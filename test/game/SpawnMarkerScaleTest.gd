extends GdUnitTestSuite

# A spawn marker's basis is copied onto the player's CharacterBody3D, so a
# marker left scaled in the editor scales the player capsule for the whole
# match. Jolt refuses a non-uniformly scaled capsule and falls back to the
# average of the three axes.
const DIRECTORY := "res://common/game/maps/map_directory.json"
const EXTRA_MAPS := [
	"res://common/game/maps/explore/ExploreMap.tscn",
]

const SPAWN_PARENTS := ["HiderSpawns", "SeekerSpawns"]


func _map_paths() -> Array:
	var file := FileAccess.open(DIRECTORY, FileAccess.READ)
	assert_object(file).override_failure_message("Cannot open %s" % DIRECTORY).is_not_null()
	var data: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()

	var paths := []
	for map in data.maps:
		paths.append(map.path)
	paths.append_array(EXTRA_MAPS)
	return paths


func test_spawn_markers_are_not_scaled() -> void:
	var checked := 0
	var scaled: Array[String] = []

	for path in _map_paths():
		var scene: PackedScene = load(path)
		assert_object(scene).override_failure_message("Cannot load %s" % path).is_not_null()
		var state := scene.get_state()

		for i in state.get_node_count():
			var node_path := str(state.get_node_path(i))
			var under_spawns := false
			for parent in SPAWN_PARENTS:
				if node_path.contains("%s/" % parent):
					under_spawns = true
			if not under_spawns:
				continue

			checked += 1
			for j in state.get_node_property_count(i):
				if str(state.get_node_property_name(i, j)) != "transform":
					continue
				var marker: Transform3D = state.get_node_property_value(i, j)
				var marker_scale := marker.basis.get_scale()
				if not marker_scale.is_equal_approx(Vector3.ONE):
					scaled.append("%s %s scale %s" % [path.get_file(), node_path, marker_scale])

	assert_int(checked).override_failure_message("No spawn markers were found to check").is_greater(0)
	assert_array(scaled).override_failure_message(
			"Spawn markers must sit at scale 1:
  %s" % "
  ".join(scaled)).is_empty()
