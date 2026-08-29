extends GdUnitTestSuite

# Converting the mesh libraries from Godot 3 binary rotated the normals of every
# tile whose vertices were left in source space: the node's rotation was applied
# to the normals but not the positions. Ground tiles that should face up ended
# up pointing sideways, so a tile only lit when the light came from that
# horizontal direction, and neighbours at different GridMap rotations lit from
# opposite sides.
#
# Only tiles whose vertex positions still match the source can be compared this
# way. Where the transform was baked into the positions as well, the normals are
# legitimately rotated to match and there is nothing to check against.
const SOURCES := [
	"res://common/game/tilesets/suburban_neighborhood/ground/ground_tiles.glb",
	"res://common/game/tilesets/suburban_neighborhood/walls/wall_tiles.glb",
	"res://common/game/tilesets/suburban_neighborhood/features/feature_tiles.glb",
	"res://common/game/tilesets/suburban_neighborhood/police_features/police_features.glb",
	"res://common/game/tilesets/suburban_neighborhood/see_through_features/see_through_features.glb",
]

const LIBRARIES := [
	"res://common/game/tilesets/suburban_neighborhood/suburban_neighborhood_ground.meshlib.res",
	"res://common/game/tilesets/suburban_neighborhood/suburban_neighborhood_features.meshlib.res",
	"res://common/game/tilesets/suburban_neighborhood/suburban_neighborhood_police_features.meshlib.res",
	"res://common/game/tilesets/suburban_neighborhood/suburban_neighborhood_see_through_features.meshlib.res",
]

const EPS := 0.0005


func test_tile_normals_match_the_source_art() -> void:
	var source := _source_meshes()
	var rotated: Array[String] = []
	var compared := 0

	for lib_path in LIBRARIES:
		var lib: MeshLibrary = load(lib_path)
		for id in lib.get_item_list():
			var key := lib.get_item_name(id).strip_edges()
			if not source.has(key):
				continue
			var ours: Mesh = lib.get_item_mesh(id)
			var theirs: Mesh = source[key]
			for s in ours.get_surface_count():
				var mine: Array = ours.surface_get_arrays(s)
				var donor := _same_geometry(theirs, mine[Mesh.ARRAY_VERTEX])
				if donor.is_empty():
					continue
				compared += 1
				var a: PackedVector3Array = mine[Mesh.ARRAY_NORMAL]
				var b: PackedVector3Array = donor[Mesh.ARRAY_NORMAL]
				for i in a.size():
					if a[i].distance_to(b[i]) > 0.01:
						rotated.append("%s/%s surf%d: %s vs source %s" % [
							lib_path.get_file(), key, s, str(a[i]), str(b[i])])
						break

	assert_int(compared).override_failure_message(
		"No comparable surfaces found; the test is not checking anything").is_greater(10)
	assert_array(rotated).override_failure_message(
		"%d surfaces have normals rotated away from the source art:\n  %s"
		% [rotated.size(), "\n  ".join(rotated)]).is_empty()


func _source_meshes() -> Dictionary:
	var out := {}
	for path in SOURCES:
		var packed: PackedScene = load(path)
		if packed == null:
			continue
		var root := packed.instantiate(PackedScene.GEN_EDIT_STATE_DISABLED)
		auto_free(root)
		_collect(root, out)
	return out


func _collect(node: Node, out: Dictionary) -> void:
	if node is MeshInstance3D and (node as MeshInstance3D).mesh != null:
		out[str(node.name).strip_edges()] = (node as MeshInstance3D).mesh
	for child in node.get_children():
		_collect(child, out)


func _same_geometry(donor: Mesh, verts: PackedVector3Array) -> Array:
	for s in donor.get_surface_count():
		var arrays: Array = donor.surface_get_arrays(s)
		var theirs: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if theirs.size() != verts.size():
			continue
		var same := true
		for i in verts.size():
			if verts[i].distance_to(theirs[i]) > EPS:
				same = false
				break
		if same:
			return arrays
	return []
