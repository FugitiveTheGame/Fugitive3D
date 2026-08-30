extends GdUnitTestSuite

# GridMap baked meshes are how a GridMap receives its lightmap: baking merges
# per-cell copies of the library meshes into the scene file and the engine
# renders those copies instead of the library. That makes them a trap: they
# freeze the library as it was at bake time, and the Godot 3 port carried
# copies with rotated normals through years of debugging.
#
# This test scores the copies STORED in each scene file against their own
# geometry. It must read via SceneState: GridMap.get_bake_meshes() silently
# regenerates fresh copies when none exist, which would hide stale disk state.
#
# Godot front faces wind clockwise, so a healthy surface's face normals score
# near -1 against its vertex normals; rotated normals score near 0. Scenes
# with no stored baked meshes pass (valid, just no lightmap on the gridmaps).
const MAPS := [
	"res://common/game/maps/freehold/Freehold.scn",
	"res://common/game/maps/cedar_point/CedarPoint.scn",
	"res://common/game/maps/littleton/Littleton.scn",
	"res://common/game/maps/grey_box/GreyBox.tscn",
	"res://client/main_menu/background/Background.scn",
]
const HEALTHY := -0.85
const MAX_TRIS_PER_SURFACE := 300


func test_stored_baked_meshes_agree_with_their_geometry() -> void:
	var offenders: Array[String] = []
	for map_path in MAPS:
		var packed: PackedScene = load(map_path)
		var state := packed.get_state()
		for n in state.get_node_count():
			if state.get_node_type(n) != "GridMap":
				continue
			for p in state.get_node_property_count(n):
				if state.get_node_property_name(n, p) != "baked_meshes":
					continue
				var baked: Array = state.get_node_property_value(n, p)
				for i in baked.size():
					var mesh: Mesh = baked[i] as Mesh
					if mesh == null:
						continue
					for s in mesh.get_surface_count():
						var score := _score(mesh, s)
						if score > HEALTHY:
							offenders.append("%s %s baked[%d] surf%d: score %.2f" % [
								map_path.get_file(), state.get_node_path(n), i, s, score])

	assert_array(offenders).override_failure_message(
		("Stale GridMap baked meshes stored in the scene: normals disagree with "
		+ "geometry, so the map renders meshes from before a library fix. "
		+ "Re-bake the map and save the scene:\n  %s")
		% "\n  ".join(offenders)).is_empty()


func _score(mesh: Mesh, s: int) -> float:
	if mesh.surface_get_primitive_type(s) != Mesh.PRIMITIVE_TRIANGLES:
		return -1.0
	var arrays := mesh.surface_get_arrays(s)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if verts.size() == 0 or normals.size() == 0:
		return -1.0
	var idx := indices if indices.size() > 0 else PackedInt32Array(range(verts.size()))
	var total := 0.0
	var tris := 0
	for t in range(0, idx.size() - 2, 3):
		var a := verts[idx[t]]
		var face := (verts[idx[t + 1]] - a).cross(verts[idx[t + 2]] - a)
		var vn := normals[idx[t]] + normals[idx[t + 1]] + normals[idx[t + 2]]
		if face.length_squared() < 1e-12 or vn.length_squared() < 1e-12:
			continue
		total += face.normalized().dot(vn.normalized())
		tris += 1
		if tris >= MAX_TRIS_PER_SURFACE:
			break
	if tris == 0:
		return -1.0
	return total / tris
