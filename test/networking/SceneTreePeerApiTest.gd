extends GdUnitTestSuite

# Godot 3 hung the network peer off the SceneTree. Godot 4 moved it to
# MultiplayerAPI, but GDScript resolves method calls at runtime, so
# get_tree().set_multiplayer_peer(peer) parses cleanly and only blows up when
# the line actually executes. Explore and the dev scenes sit off the main
# multiplayer path, so they kept the dead call long after Phase 2 migrated
# everything else.
const REMOVED_SCENETREE_CALLS := [
	"get_tree().set_multiplayer_peer",
	"get_tree().network_peer",
	"get_tree().set_network_peer",
	"get_tree().is_network_server",
	"get_tree().get_network_unique_id",
]


func test_the_scene_tree_no_longer_carries_the_peer() -> void:
	assert_bool(ClassDB.class_has_method("SceneTree", "set_multiplayer_peer", true)
		).override_failure_message(
		"SceneTree grew the method back; this guard needs revisiting").is_false()


func test_no_script_sets_the_peer_on_the_scene_tree() -> void:
	var offenders: Array[String] = []
	_scan("res://", offenders)
	assert_array(offenders).override_failure_message(
		"These call SceneTree methods that no longer exist, and fail only at runtime:\n  %s"
		% "\n  ".join(offenders)).is_empty()


func _scan(dir: String, offenders: Array[String]) -> void:
	var d := DirAccess.open(dir)
	if d == null:
		return
	d.list_dir_begin()
	var entry := d.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = d.get_next()
			continue
		var full := dir.path_join(entry)
		if d.current_is_dir():
			if full != "res://addons" and full != "res://test":
				_scan(full, offenders)
		elif entry.ends_with(".gd"):
			var text := FileAccess.get_file_as_string(full)
			for call in REMOVED_SCENETREE_CALLS:
				if text.contains(call):
					offenders.append("%s -> %s" % [full, call])
		entry = d.get_next()
	d.list_dir_end()
