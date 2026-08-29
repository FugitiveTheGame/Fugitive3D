extends GdUnitTestSuite

# Godot 3 spelled this use_in_baked_light. Godot 4 has only gi_mode, so the old
# name is ignored on load and every mesh falls back to STATIC, which is the
# opposite of what these scenes ask for. Players and light fixtures then get
# treated as bakeable level geometry: the fixture is burned into the lightmap,
# and the characters stop being lit as the moving objects they are.
const MOVABLE_SCENES := [
	"res://common/game/mode/fugitive/motion_sensor/garage_light.tscn",
	"res://common/game/mode/fugitive/hider/assets/body_standing/hider_standing_body.tscn",
	"res://common/game/mode/fugitive/hider/assets/body_crouching/hider_crouching_body.tscn",
	"res://common/game/mode/fugitive/seeker/assets/body_standing/seeker_standing_body.tscn",
	"res://common/game/mode/fugitive/seeker/assets/body_crouching/seeker_crouching_body.tscn",
]


func test_movable_meshes_are_kept_out_of_the_lightmap() -> void:
	var still_baked: Array[String] = []

	for path in MOVABLE_SCENES:
		var scene: PackedScene = load(path)
		assert_object(scene).override_failure_message(
			"Could not load %s" % path).is_not_null()

		var root: Node = scene.instantiate()
		auto_free(root)

		for node in _geometry(root):
			if node.gi_mode != GeometryInstance3D.GI_MODE_DISABLED:
				still_baked.append("%s -> %s" % [path.get_file(), root.get_path_to(node)])

	assert_array(still_baked).override_failure_message(
		"These move at runtime but are flagged as bakeable static geometry: %s"
		% str(still_baked)).is_empty()


func _geometry(node: Node, found: Array[GeometryInstance3D] = []) -> Array[GeometryInstance3D]:
	if node is GeometryInstance3D:
		found.append(node)
	for child in node.get_children():
		_geometry(child, found)
	return found
