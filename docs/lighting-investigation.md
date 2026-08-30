# Lighting investigation

Working notes on the Godot 4 lighting problems. Written to hand the work to the
desktop. Everything here was measured, not inferred; where something is a guess
it says so.

## The symptoms

1. **Tiles light from one side only.** Point the flashlight at a grass tile, run
   to the other side, turn around, light it again: what was lit is now dark, and
   the neighbouring tile has swapped with it. Hard boundaries along tile edges.
2. **House faces stay dark** while the white trim beside them lights up.
3. **Trees lit on some faces only**, with jagged polygon-edge boundaries.
4. **The whole scene is far darker than the Godot 3 build.** See
   `lighting-reference` screenshot: there, materials read true (green grass,
   white fence, warm pools by the street lights) and the base level is much
   higher.
5. Baking initially made things *darker* than not baking.

## Root cause found: the mesh library normals were rotated

Converting the libraries from Godot 3 binary applied **each mesh's own node
rotation to its normals while leaving the vertex positions alone**. The geometry
sat correctly and the normals pointed somewhere else entirely.

```
                    SOURCE .glb            BROKEN meshlib
road_blank          (0.00, 1.00, 0.00)     (0.00, 0.00, -1.00)
yard_grass_only     (0.00, 1.00, 0.00)     (0.71, 0.00, -0.71)
```

Ground tiles that should face up ended up horizontal. A surface whose normal
points sideways only lights when the light arrives from that horizontal
direction, so walking to the other side flips the sign of N·L. Neighbouring
cells sit at different GridMap rotations, so their sideways normals aim opposite
ways: hence the anti-correlation.

Scope when found: **34 surfaces** across all four libraries. 12/12 ground tiles,
8/10 wall tiles, 9/10 features, 1/2 police features.

**Fixed in `5c75abcd`.** Normals and tangents copied back from the `.glb`
sources, per surface, only where vertex positions still match so the pairing
cannot be wrong. Item ids, names, collision shapes, previews and materials
untouched (GridMap cells reference items by id, so a full re-export would
renumber them and scramble every map).

Verified live: the `GroundGridmap` that Explore actually loads reports
`yard_grass_only` normal `(0.0, 1.0, -0.000015)`. Guarded by
`test/game/MeshLibraryNormalsTest.gd`.

## Other lighting fixes already made

| fix | commit | what it did |
|---|---|---|
| `ambient_light_sky_contribution` 1.0 → 0.0 | `f8836358` | Godot 3 defaulted this to 0, Godot 4 to 1, so the configured blue ambient contributed nothing |
| LightmapGI `environment_mode` SCENE → CUSTOM_COLOR | `9f356290` | the bake's only ambient source was a dim night sky, so baking removed more light than it added |
| `use_in_baked_light` → `gi_mode` | `f8836358` | dead Godot 3 property; the garage light and all four player bodies were being baked as static level geometry |
| Background.scn given the same LightmapGI settings | `0d07bc23` | standalone scene, missed the settings the maps inherit |
| Freehold `light_data` linked | `74deb6df` | bake existed but nothing referenced it |

## Ruled out, with the method used

Each of these was tested directly, not reasoned about:

| suspect | how it was tested | result |
|---|---|---|
| Lightmap data | `light_data = null` at runtime, same camera | scene dimmer, **cone boundary identical** |
| Shadows | `shadow_enabled = false` on all 40 spotlights | identical |
| GridMap octants | `cell_octant_size = 1` on all four GridMaps | identical |
| Materials | measured every yard tile | byte-identical `grass` material, metallic 0, roughness 1 |
| Half-house pairing | audited all 102 half-house cells | every one correctly paired and oriented |
| `params_cull_mode` compat | loaded materials and read `cull_mode` | Godot 4 honours the Godot 3 name; all 163 load as CULL_DISABLED |
| `flags_unshaded` / `flags_transparent` | loaded and read `shading_mode` / `transparency` | compat mapping works |
| LightmapGI ignoring GridMaps | checked the engine issue | real bug, but fixed in Godot 4.2 by PR #81545 |
| Flashlight beam cone occluding | read `lightbeam.tscn` | `cast_shadow = 0`, casts nothing |
| Siding albedo | measured effective albedo per material | blue siding *is* 3.5x darker than yellow, but this is not the cause; identical materials on adjacent tiles behave differently |

## Facts about this project's lighting worth knowing

- **`turn_off_baked_lights()` hides every light in the `baked_lights` group at
  runtime.** Away from the player's flashlight, the only illumination is the
  lightmap plus ambient. Street lights contribute *only* through the bake.
- **The editor viewport is not representative.** `FugitiveMap.gd` and
  `Background.gd` are not `@tool` scripts, so that function never runs there:
  the editor shows the bake *plus* every baked light rendering in real time.
  Always judge lighting in the running game.
- **`ExploreMap.tscn` inherits `Freehold.scn`.** Explore is Freehold with
  different spawn points and no LightmapGI of its own, so changes to Freehold's
  bake do affect Explore.
- **Lightmapped surfaces stop receiving the Environment's ambient**, on the
  assumption the bake contains it. The lightmapper samples the *sky*, not
  `ambient_light_color`.
- Flashlight: `light_energy = 14`, `spot_range = 30`,
  `light_color = (0.898, 0.902, 0.75)`, `shadow_bias = 0.5`.

## Still open

1. **The desktop re-baked after the normals fix and reports no visible change.**
   Not yet verified whether that bake happened on a checkout that actually
   contained `5c75abcd`, or whether `light_data` linked afterwards. Both must be
   confirmed before drawing any conclusion from it.
2. **A rectangular lit tile** appeared in one screenshot: a perfect rectangle of
   lit grass with its neighbours dark inside the same cone. Consistent with the
   normals bug, but never confirmed after the fix.
3. **Overall brightness against the Godot 3 reference.** Ambient was being
   nudged upward to compensate for lighting that was broken at the source, so
   those numbers should be re-judged now rather than trusted.
4. Meshes whose transform was baked into their positions (houses, trees, signs)
   had no valid source to compare against, so their normals were left alone. If
   something still looks wrong, that is where to look next.

## Next steps on the desktop

1. Confirm the checkout contains the normals fix: `git log --oneline -1` should
   be `84a63f04` or later.
2. Re-bake, **save the scene**, then confirm the LightmapGI's `Light Data` is
   populated. This has silently failed three times (CedarPoint, Littleton,
   Freehold); an unlinked bake is indistinguishable from no bake.
3. Test the flip specifically, not overall brightness: light a grass tile, walk
   to the other side, light it again. If it stays lit, the normals fix works and
   only calibration remains.
4. If it still flips with correct normals baked in, sample the lightmap texture
   directly rather than judging by eye.

## Wrong turns, so they are not repeated

- **Checking normals in the `.glb` source and concluding the models were fine.**
  The source was always correct; the corruption was in the meshlib. The
  comparison that matters is source *versus* library. This cost the most time.
- Blaming the blue siding's albedo. The difference is real and measurable but
  adjacent tiles with an *identical* material behaved differently, which ruled
  it out.
- Claiming inverted normals on `house_half_*` from a single-angle comparison of
  two differently shaped models. Not a valid comparison.
- Suggesting the bake's ambient energy be lowered. The Godot 3 reference is
  *brighter*; that was backwards.
- Reading per-triangle winding against smoothed vertex normals. Too noisy to
  conclude anything.
