# Fugitive3D: Godot 3.x to 4.7 Port Plan

Goal: resurrect the game on Godot 4.7.2, first as a working flat multiplayer game, then rebuild VR on OpenXR so it runs on modern headsets.

Working rules for this effort:

- All work on a branch (`godot4-port`), master stays 3.x until the port is playable.
- Bug fixes follow TDD once the test harness exists (Phase 3): failing gdUnit4 test first, then the fix. Chicago style, assert outcomes not implementation.
- The godot-mcp server (Godot 4.7.2 at `~/.config/itch/apps/godot/Godot_v4.7.2-stable_linux.x86_64`) is used to validate scripts, run scenes, and read errors instead of guessing.

## Current state inventory

Game code (excluding addons): ~8,450 lines of GDScript across 126 scripts, ~106 scenes.

| Area | Count | Notes |
|---|---|---|
| `remote func` | 11 | server-authoritative handlers |
| `remotesync func` | 37 | call-on-all handlers |
| `puppet func` | 2 | |
| `rset` | 0 | none, big relief |
| `yield(` | 0 | none, no coroutine migration |
| `rpc(` / `rpc_id(` / `rpc_unreliable` | 26 / 17 / 8 | unreliable = movement sync |
| `onready var` | 186 | converter handles (`@onready`) |
| `export(` | 106 | converter handles (`@export`) |
| old-style `connect(` | 86 | converter handles, verify each |
| `setget` | 11 | becomes property get/set, manual |
| `.instance()` | 21 | becomes `instantiate()` |
| `find_node(` | 16 | becomes `find_child()` |
| `change_scene(` | 18 | becomes `change_scene_to_file()` |
| `WindowDialog` refs | 20 | class removed in 4.x, use `Window` or `AcceptDialog` |
| `move_and_slide` | 5 | signature changed, velocity is a property now |
| custom shaders | 2 | shader language changes, review by hand |

Autoloads: ClientNetwork, ServerNetwork, GameData, vr (OQ_Toolkit), UserData, Maps, GameAnalytics, Feedback, ServerAdvertiserData.

### Addon disposition

| Addon | Type | Fate in 4.x |
|---|---|---|
| godot-oculus | GDNative | Delete. Built-in OpenXR covers it |
| godot-openvr | GDNative | Delete. Built-in OpenXR covers it |
| godot_ovrmobile | GDNative | Delete. OpenXR + vendors plugin covers Quest |
| OQ_Toolkit | GDScript on old backends | Delete. Replace with godot-xr-tools v4.5.x |
| opus | GDNative | Ported to a GDExtension upstream and integrated in Phase 5. Windows/Linux/macOS/Android arm64 binaries ship in `addons/opus/` |
| LANServerBroadcast | Pure GDScript | Port with converter, small API fixes (PacketPeerUDP is similar in 4.x). Check upstream for an existing Godot 4 branch first |
| Godot-GameAnalytics | Pure GDScript | Port with converter, HTTPRequest API mostly unchanged. Check upstream too |
| UUID, TimeUtils | Pure GDScript | Trivial |
| Fugitive3D (editor plugin) | GDScript | Review, likely trivial |

## Phase 0: Prep

1. Create `godot4-port` branch.
2. Snapshot baseline behavior notes: how a host + 2 clients flow works in 3.x (lobby, countdown, game start, win conditions), so we can verify parity later. The README and a quick 3.x run (if an old editor is still around) inform this; otherwise reconstruct from code.
3. Delete dead addons up front (`godot-oculus`, `godot-openvr`, `godot_ovrmobile`, `OQ_Toolkit`) so the converter does not waste effort on them and broken GDNative refs do not mask real errors. Keep the VR game scenes; they will be rebuilt in Phase 4.
4. Remove the `vr` autoload and stub the ~12 `vr.*` call sites in shared code (`vr.initialize`, foveation and refresh-rate tuning, `vr.is_oculus_quest_*`) behind a small `VrCompat` shim that no-ops until Phase 4.

Exit criteria: project still opens in Godot 3 semantics conceptually (not runnable, that is fine), tree is clean of GDNative.

## Phase 1: Automated conversion

1. Run `godot --headless --path . --validate-conversion-3to4 | tee conversion-report.txt`, review.
2. Run `godot --headless --path . --convert-3to4`.
3. Commit immediately (pure converter output, reviewable as one diff).
4. Known converter gaps to sweep by hand afterward:
   - Comments get mangled (the converter renames words like "on" inside comments). Review the diff for comment damage.
   - The 2 custom shaders: `hint_albedo` and similar hints changed, review manually.
   - Particles nodes (8 refs): GPUParticles3D property renames are lossy in places.
   - CSG and SpatialMaterial (now StandardMaterial3D) property renames in scenes.
   - `WindowDialog` (20 refs) does not exist in 4.x. Convert VR HUD dialogs and flat menus to `Window`/`AcceptDialog`/`ConfirmationDialog`.
   - `OS.get_system_time_msecs()` becomes `Time.get_ticks_msec()`, `OS.get_unix_time()` becomes `Time.get_unix_time_from_system()`.
   - GridMap maps (FugitiveSuburbanMap, ExploreMap) and their 5 binary `.meshlib` files: GridMap still exists in 4.x, but if any MeshLibrary converts badly, regenerate it from the tileset source scenes in `common/game/tilesets/` via the editor's Convert to MeshLibrary.
5. Open the project in the 4.7.2 editor once so `.godot/` regenerates and import errors surface. Then use `mcp` script validation (`validate_scripts`) to iterate on parse errors until the project loads with zero script errors.

Exit criteria: project opens in 4.7.2, all scripts parse, main scene loads (flat client path may still crash at runtime, that is Phase 2/3 work).

## Phase 2: Multiplayer migration

The 3.x high-level multiplayer maps cleanly since we never used `rset`:

| Godot 3.x | Godot 4.x |
|---|---|
| `remote func f()` | `@rpc("any_peer") func f()` plus explicit sender checks |
| `remotesync func f()` | `@rpc("any_peer", "call_local") func f()` |
| `puppet func f()` | `@rpc("authority") func f()` |
| `rpc_unreliable("f", ...)` | `@rpc(..., "unreliable")` on the target, call via `rpc()` |
| `get_tree().network_peer = peer` | `multiplayer.multiplayer_peer = peer` |
| `NetworkedMultiplayerENet` | `ENetMultiplayerPeer` |
| `get_tree().get_network_unique_id()` | `multiplayer.get_unique_id()` |
| `get_tree().is_network_server()` | `multiplayer.is_server()` |
| `get_tree().connect("network_peer_connected", ...)` | `multiplayer.peer_connected.connect(...)` |
| `connected_to_server`, `server_disconnected`, `connection_failed` | same signals on `multiplayer` |
| `is_network_master()` | `is_multiplayer_authority()` |

Files, in dependency order:

1. `networking/BaseNetwork.gd`, `ServerNetwork.gd` (11 handlers), `ClientNetwork.gd` (10 handlers), `GameData.gd`, `PlayerData.gd`
2. `server/` (5 scripts): dedicated server entry, joinability
3. Game-mode RPCs in `common/game/mode/fugitive/` (CopCar, Flashlight, RemoteHider, RemoteSeeker, hider/seeker logic, win conditions)
4. Client controllers: `FlatFugitiveController`, `FlatPlayerController` movement sync
5. `LANServerBroadcast` addon (UDP discovery)

Behavioral traps to watch:

- 4.x RPCs require the annotation config on the receiving method; a `remote` func that was called by anyone must be `"any_peer"` and must validate `multiplayer.get_remote_sender_id()` where 3.x relied on convention. `ServerNetwork.on_register_self` and friends should check sender identity where it matters.
- `compression_mode = 4` (Zstandard) on ENet: set `peer.host.compress(...)` equivalent via `ENetConnection` compression enum, verify both ends match.
- 3.x allowed calling an RPC on a node whose remote counterpart was not yet in the tree; 4.x logs errors more aggressively for missing nodes/mismatched paths. Watch the movement RPCs during join/leave races.
- `Entry.gd` uses `OS.has_feature("server"|"client")`: in 4.x, dedicated server builds use the `dedicated_server` feature tag and export template. Update `Entry.gd` detection and the export presets together.

Exit criteria: dedicated server boots headless, two flat clients on localhost can join the lobby, see each other, change teams, start a game.

## Phase 3: Flat gameplay verification and test harness

1. Install gdUnit4 (current stable line, supports 4.7.x).
2. Seed the harness with outcome tests around the pure logic that needs no scene tree:
   - `GameData` player registration, host reassignment on disconnect (the `_player_disconnected` path)
   - sequence-number rollover logic in `ClientNetwork.getNextSequence`
   - team randomization layout (`on_randomize_teams` team resolver outcomes)
   - win-condition logic in the fugitive game mode
   These double as regression nets for the port itself.
3. Playtest the full flat loop via mcp (`run_project`, screenshots, logs): lobby, countdown, hider/seeker round, cop car, flashlight, win/lose, return to lobby.
4. Physics pass: `move_and_slide` call sites (Player, CopCar), collision layers, `Area3D` signals (14 Area refs), stairs/step behavior differences between 3.x and 4.x KinematicBody/CharacterBody3D.
5. Rendering pass: lighting and environment re-tune (renderer changed completely), the 2 shaders, particles. Choose Forward+ for desktop; the Quest build will want the Mobile renderer, verify shared materials look acceptable on both.
   - Lightmaps: BakedLightmap is now LightmapGI, old bakes do not convert. Delete the 4 stale `.lmbake` files (Freehold and CedarPoint are 13MB each) and re-bake with the GPU baker (desktop Forward+ to bake, renders fine on Mobile renderer). The 3.x dynamic-object light octree is replaced by auto-placed SH probes, so expect smaller data. Bake one GridMap-based map EARLY: GridMap baking was broken until 4.1.3 and still has open quirks (MeshLibrary transform glitch godot#95436, cast-shadow setting ignored godot#116775).
6. From here on, the TDD rule applies: every gameplay bug found in playtesting gets a failing gdUnit4 test first where the bug is testable logic; scene/physics-only bugs get a manual repro note instead.

Exit criteria: full flat game round is playable multiplayer with no errors in logs; test suite green; this is the milestone worth merging or at least tagging.

### Phase 3 status (2026-08-29)

Verified end to end with a dedicated server plus two clients: main menu, LAN
discovery, join, lobby sync, team select, countdown, map load, spawns,
movement and collision, seeker capture, freeze, win condition, `game_over via:
end_game`, replay map, stats (arrests and captures counted correctly), return
to lobby, and score persistence into the next lobby. Cop car verified
separately: enter, throttle, MAX_SPEED cap, friction, and stable ground
contact while driving ~30 units. 10 gdUnit4 tests green.

Fixed here: ground tiles had no collision because Godot 4 makes
ConcavePolygonShape3D one-sided by default (see the collision section below).

Still open for Phase 3:

- Rendering pass and the LightmapGI re-bake, which needs a human eye and the
  editor; deliberately left for a session with the user awake.
- Deprecation warnings worth clearing while touching the renderer: meshes
  using the old surface format (StreetLight.tscn and the tileset meshlibs
  load slower), and `lightbeam.gdshader` using pre-4.x parameter names.
- `CopCar.gd` has two `velocity = velocity` no-ops at the move_and_slide call
  sites, converter debris now that move_and_slide updates velocity in place.
- Second round in one session could not be started from the test harness: the
  auto-return-to-lobby timer only starts when the HOST clicks "Return to
  Lobby", so a headless bot host strands everyone on the end screen. Matches
  3.x behaviour, not a port regression, but it is fragile for real players.

### Lightmap re-bake: prep done, the bake itself is a manual editor step

`LightmapGI` exposes no `bake()` to scripting, so the bake must be triggered
from the editor. Everything it needs is now in place:

- All 232 lights in the `baked_lights` group across Freehold (77), CedarPoint
  (89), Littleton (41) and GreyBox (25) are `BAKE_STATIC`. They were
  `light_bake_mode = 2`, which meant BAKE_ALL in Godot 3 but means
  BAKE_DYNAMIC in Godot 4, so the converter silently flipped every baked light
  to "never bake". Fixed at the source in StreetLight.tscn and
  FugitiveSuburbanMap.tscn, which propagates to every map.
- All 38 tileset meshes still carry UV2, which LightmapGI requires.
- Map geometry is `gi_mode = STATIC` (95 of 97 MeshInstance3D; the 2
  disabled ones are deliberate).
- A `LightmapGI` node is on FugitiveSuburbanMap.tscn, so every map inherits
  one. It now sits at `quality = 2` with `supersampling` on and
  `denoiser_strength = 0.3`, which is what finally brought the speckle noise
  down to an acceptable level.

Note that until a bake exists the maps render dark, because `FugitiveMap`
calls `Utils.turn_off_baked_lights()` which hides every `baked_lights` member
on the assumption their light lives in the lightmap.

To bake: open a map scene (for example `common/game/maps/freehold/Freehold.scn`),
select the LightmapGI node, and use the "Bake Lightmaps" button in the toolbar.
Repeat per map, since bake data is per-scene. Then raise `bake_quality` and
`bounces` once the result looks right. If the output is too large, which was
the complaint about the 3.x bakes, lower `texel_scale` and `max_texture_size`
before raising quality, and leave `directional` off.

### Properties the 3-to-4 converter changed without saying so

This is the recurring failure mode of the port. The converter leaves a Godot 3
name or number in place, Godot 4 either ignores it or reads it as something
else, and nothing warns. Found so far:

| What | Godot 3 | Godot 4 | Effect |
|---|---|---|---|
| `light_bake_mode = 2` | BAKE_ALL | BAKE_DYNAMIC | every baked light excluded from the lightmap |
| `emission_shape = 2` | BOX | SPHERE_SURFACE | fireflies clumped onto a 1m sphere |
| `initial_velocity`, `linear_accel`, `damping`, `*_random` | real properties | replaced by `_min`/`_max` | all particle motion fell to zero |
| `generate_lightmap` | real property | replaced by `gi_mode` | light beam cones baked into the lightmap |
| `shader_param/x` | real | now `shader_parameter/x` | works via a compat path, warns on every load |
| light attenuation of `1.0` | linear falloff | adds a distance decay term | near field blown out, far field dark |
| `use_in_baked_light` | real property | replaced by `gi_mode` | players and the garage light fixture baked as static level geometry |
| `ambient_light_sky_contribution` | defaulted to 0 | defaults to 1 | the configured ambient colour contributes nothing, so unlit ground reads pure black |
| `get_tree().set_multiplayer_peer()` | the peer lived on SceneTree | moved to MultiplayerAPI | parses fine and fails only when the line runs, so Explore and the dev scenes stayed broken well past Phase 2 |
| `image.create()`, `imageTexture.create_from_image()` | instance methods | now static | the call builds a new object and discards it, leaving the original empty; the map view logged "Invalid image: image is empty" |
| dialogs cast `as Control` | WindowDialog was a Control | Window derives from Viewport | the cast yields null, and the reference only fails when the dialog is opened |
| dialogs keep `anchor_*` / `offset_*` | those sized a WindowDialog | Window is sized by `size` | the anchors are ignored, so every dialog falls back to Godot's 100x100 default and clips its own contents |
| mesh library normals | matched the source art | rotated by each mesh's own node transform, positions left alone | ground tiles ended up facing sideways, so a surface lit only from one horizontal direction and neighbours at different GridMap rotations lit from opposite sides |

Before Phase 4, sweep for the rest of this class rather than finding them one
screenshot at a time. Enum values whose meaning shifted are the nastiest,
since the value still loads and looks plausible.

### Lightmap baking is a desktop job

Supersampling multiplies bake time roughly fourfold, which is painful on the
laptop. Bake on the workstation instead. The LightmapGI settings live on
FugitiveSuburbanMap.tscn so all maps inherit them, and Background.scn carries
its own.

Every bake was deleted before this branch was pushed, so all four maps render
unlit right now and need a fresh one: Freehold, CedarPoint, Littleton and the
menu Background.

Two traps:

- **Check the bake actually linked.** CedarPoint and Littleton had complete
  .exr and .lmbake files on disk that neither scene referenced, so 99MB of
  bake was never applied in game. Baking writes the file, but the scene only
  points at it once the scene itself is saved. After baking, save the scene
  and confirm the LightmapGI node has `light_data` set.
- **Do not push intermediate bakes.** A full set is well over 100MB of EXR
  through LFS against a 1GB free tier. Bake, evaluate, then push once.

### Baking removes the ambient you configured

A lightmapped surface stops receiving the Environment's ambient light: Godot
assumes the bake already contains it. But the lightmapper samples the *sky*, not
`ambient_light_color`, and this project's sky is a dim night panorama at half
energy. On the default `environment_mode = SCENE` the bake therefore lands with
almost no ambient, and baking makes the map darker than it was unbaked.

FugitiveSuburbanMap.tscn's LightmapGI now uses `environment_mode = 3`
(CUSTOM_COLOR) with the same blue the Environment uses.
`environment_custom_energy` is the dial: raise it for a brighter night, lower it
for a darker one. It is the one value to tune before spending a long bake.

### Lighting investigation

The lighting work has its own notes in docs/lighting-investigation.md: symptoms,
the mesh library normal corruption that caused most of it, what has been ruled
out and how, and what is still open.

### Judge lighting in the running game, not the editor viewport

`FugitiveMap.gd` and `Background.gd` call `Utils.turn_off_baked_lights()` from
`_ready`, and neither is a `@tool` script, so it never runs in the editor. The
editor therefore shows the baked lightmap *plus* every baked light rendering in
real time on top of it, which is a combination that never occurs at runtime.
Street lights in particular look wrong there: they are `BAKE_STATIC`, so their
real-time `shadow_enabled`/`shadow_bias = 0.5` settings only affect the editor
preview and are irrelevant in game.

Run the game to evaluate a bake.

### Resources are compressed binary, not text

Meshes, materials and meshlibs were briefly stored as text .tres so the 3-to-4
converter could read them. Text writes vertex arrays and embedded 1024x1024
images as decimal numbers, roughly five bytes per stored byte, which is how the
tree reached 354MB. They are now compressed binary .res: 23MB for the same 200
resources, small enough to drop out of LFS entirely.

Regenerate them as .res, not .tres. If one has to be edited as text, convert it
back afterwards.

One git trap worth knowing: if `filter.lfs.smudge` is ever set to `--skip`,
checkouts silently write pointer files instead of real content, and `git status`
will not report those files as modified.

### Ground collision: trimesh tiles were one-sided

Symptom: a player runs across a yard for a few seconds, then falls through
the world. Cause: Godot 4 defaults `ConcavePolygonShape3D.backface_collision`
to false, so a trimesh floor only collides from one side. 286 of Freehold's
725 ground cells (every yard, sidewalk, house and the apartment) had no
collision at all; the map only felt solid where a fence or bush happened to
sit above the gap, which is why it took a few seconds of running to find one.
Fix: `backface_collision = true` on all 35 tileset trimesh shapes. Guarded by
`test/game/TilesetCollisionTest.gd`, which drops each ground tile into an
isolated GridMap and asserts a downward ray hits it.

## Phase 4: VR rebuild on OpenXR + godot-xr-tools

Replace the OQ_Toolkit layer. Scope is ~15 files under `client/`:

- `client/game/player/controller/vr/`: VrPlayerController (259 lines, the big one), Locomotion_Stick, Feature_PlayerCollision, scenes
- `client/game/mode/fugitive/`: VrFugitiveController, VrHiderController, VrSeekerController
- `client/vr_menu_player/`, `client/main_menu/vr/`, `client/lobby/vr/`
- VR HUD: wrist-mounted UI on the left controller (HudCanvas hierarchy), UI raycast pointer on the right

Approach:

1. Add godot-xr-tools v4.5.x (asset library) and enable the OpenXR interface in project settings. Desktop PCVR needs no plugin at all.
2. Recreate the VR rig: `XROrigin3D` + `XRCamera3D` + two `XRController3D`, XR Tools `MovementDirect` + `MovementTurn` replace `Locomotion_Stick`, XR Tools `PlayerBody` replaces `Feature_PlayerCollision` and the custom crouch logic (VrPlayerController measures standing height and detects physical crouch: port this logic onto PlayerBody).
3. Replace `vr.button_just_released(...)` debounce layer with 4.x XR action map (the OpenXR action system replaces raw button ids; the debounce hack likely dies entirely).
4. Wrist HUD: `SubViewport` + XR Tools `Viewport2Din3D` replaces the OQ HudCanvas stack; UI raycast pointer comes from XR Tools `FunctionPointer`.
5. Reconnect the movement network sync in `VrPlayerController` (same RPC as flat, already ported in Phase 2).
6. `VrCompat` shim from Phase 0 gets real implementations: OpenXR init check, refresh rate via `OpenXRInterface.set_display_refresh_rate`, foveation via project settings / vendors plugin.
7. Regression check for a known 3.x bug: OQ teleported the collision capsule to the camera every physics tick (no sweep), so snap turning near walls let players clip through. XR Tools PlayerBody sweeps camera displacement via move_and_slide, which should fix it structurally. Verify explicitly: snap turn while pressed against a wall, and roomscale-walk into a wall, on both desktop and Quest.
8. Optional anti-cheat polish: camera fade-to-black when the head itself intersects geometry (PlayerBody stops the body, not the skull; matters for hide-and-seek sightlines).
9. Desktop PCVR test first (SteamVR/monado on Linux, or Windows build), then Quest:
   - Install the Godot OpenXR Vendors plugin (its setup wizard configures the Android export).
   - One APK now covers Quest and other Android headsets (Khronos loader is embedded since 4.6).
   - Mobile renderer, re-check `camera.far` and foveation tuning that OQ code did per-device.

Exit criteria: VR client joins a flat-hosted game on a modern headset (Quest 3 presumably), full round playable cross-play VR + flat.

## Phase 5: Voice chat

Design in Godot 3: push-to-talk recorded via `AudioEffectRecord` on a Record bus,
encoded the whole utterance with the opus GDNative node, sent one blob over RPC;
the receiver decoded it and played it as an `AudioStreamWAV`. Latency was the
length of the utterance, capped at 10s by the transmit limit timer.

Now streaming. The opus port landed as a GDExtension
([libopus-gdnative-asset](https://github.com/Godot-Opus/libopus-gdnative-asset))
with a per-frame API that sits between `AudioEffectCapture` and
`AudioStreamGenerator`, so voice goes out as 20ms Opus packets while the key is
held rather than as one blob on release.

What the integration changed:

1. `addons/opus/` holds the GDExtension, with binaries for Windows x86_64, Linux
   x86_64, macOS universal and Android arm64. No plugin activation; GDExtensions
   load on editor start. `OpusStub` is gone.
2. The Record bus carries an `AudioEffectCapture` instead of an
   `AudioEffectRecord`, and `audio/driver/mix_rate` is pinned to 48000. Opus does
   not accept Godot's default 44.1kHz and the extension does not resample.
3. `VoiceChatTransceiver` pumps capture into `push_audio()` each frame and drains
   `pop_packet()` while `has_packet()` is true, numbering packets as it goes.
   `reset_stream()` and `clear_buffer()` run at the start of each burst so
   audio captured before the key went down is not transmitted.
4. `VoiceChatReceiver` plays into an `AudioStreamGenerator`, pushing each
   `decode_frame()` result at `push_buffer()`. The RPC is `unreliable_ordered`,
   so a gap in the sequence numbers means loss, and up to three missing frames
   are filled with `decode_dropped()` concealment. A 0.5s silence ends the burst
   and resets the decoder.
5. Distance/team gating (maxTeamHearingRange, maxHearingRange) is unchanged, but
   now runs per packet rather than per utterance, so range is re-evaluated as
   players move mid-sentence.

In-earshot audio lands on a per-speaker receiver node, so those streams are
independent. The radio and post-game paths are the exception: they all route to
the listener's own transceiver, which has one decoder, so the first speaker holds
it and the rest are dropped until they stop. The Godot 3 build had the same
one-at-a-time ceiling, it just queued the losers instead of dropping them. Real
concurrent radio needs a decoder and generator per sender on that node.

Both codec nodes run mono (`channels = 1`) at the 15kbps default bit rate. The
source is a single mic, so the streaming API downmixes the stereo capture frames
on encode and duplicates the signal back into both channels on decode, which
spends the whole bit budget on one real channel instead of a duplicated pair.
Encoder and decoder have to agree, so change both together if this is revisited.

Exit criteria: two clients exchange push-to-talk audio, both flat and VR,
including Quest mic.

## Phase 6: Exports and release plumbing

- Rebuild all 11 export presets for 4.x templates: flat Windows/Linux/macOS/Android, VR Windows, VR Quest (the two separate Oculus Desktop / OpenVR presets collapse into one PCVR preset), server Windows/Linux/macOS.
- Server presets move to the 4.x dedicated server export type; align `Entry.gd` feature detection (Phase 2 note).
- macOS: existing export shipped as dmg; 4.x signing/notarization settings differ, revisit.
- GameAnalytics, feedback endpoint, and ServerRepository URL (`repository.fugitivethegame.online`): verify the backend still exists before spending time here, this may be dead infrastructure to strip or replace.

## Fixed: first-configured client dropped during game start

Cause: ENet's default 5s peer timeout versus a map load that blocks the main
thread for ~7s. The client that finished pre_configure first then sat idle
waiting for the others, missing acks the whole time, so ENet dropped it. Both
ends now call set_timeout with PEER_TIMEOUT_MIN_MS/MAX_MS (60s/120s), defined
in ServerNetwork and covered by test/networking/PeerTimeoutTest.gd. Verified
by a full round reaching `new state: playing via: cops_released` with both
players connected. An earlier 10s attempt was too close to the stall to help,
which is why the first fix looked like it failed.

## Risks and unknowns

1. Physics feel: 4.x Godot Physics behaves differently from 3.x Bullet (CopCar handling, player movement, stairs). Budget tuning time; outcome tests on speeds/thresholds help.
2. Renderer look: lighting will not match; the maps will need environment re-tuning by eye.
3. Quest hardware validation needs a real headset session; emulators will not answer comfort/perf questions.
4. Voice chat now streams over `unreliable_ordered` RPCs at 50 packets/sec per listener. In a full lobby that is a lot more small packets than the old one-blob-per-utterance design; watch bandwidth and ENet behaviour during the Phase 5 exit test.
5. Server discovery infra (ServerRepository) may be offline; LAN discovery works regardless.
6. Converter comment mangling: budget one careful diff review pass on the Phase 1 commit.

## Suggested session breakdown

1. Session A: Phases 0-1 (branch, prune, convert, parse-clean). Mostly mechanical.
2. Session B: Phase 2 (multiplayer) through "two clients in a lobby".
3. Session C: Phase 3 (playable flat round, gdUnit4 harness). Milestone tag: `godot4-flat`.
4. Session D-E: Phase 4 (VR rig, then headset-in-hand tuning with you).
5. Session F: Phases 5-6 (voice, exports).
