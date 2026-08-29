extends GdUnitTestSuite

# "as Control" on a Window-derived dialog silently yields null instead of
# erroring, so a bad cast only blows up when the menu opens at runtime.
#
# Asserts on the declaration rather than instantiating: this scene has no
# Player node until spawn, so standing it up alone throws unrelated errors.
const CONTROLLER_SCRIPT := "res://client/game/player/controller/flat/FlatPlayerController.gd"
const CONTROLLER_SCENE := "res://client/game/player/controller/flat/FlatPlayerController.tscn"
const DIALOG_VARS := ["exitGameHud", "helpDialog", "inGameMenu"]


func test_dialog_references_are_cast_to_window() -> void:
	var text := FileAccess.get_file_as_string(CONTROLLER_SCRIPT)
	var wrong: Array[String] = []

	for var_name in DIALOG_VARS:
		for line in text.split("\n"):
			var trimmed: String = line.strip_edges()
			if trimmed.begins_with("@onready var %s " % var_name) and not trimmed.ends_with("as Window"):
				wrong.append(trimmed)

	assert_array(wrong).override_failure_message(
		"These dialogs are Windows, not Controls, so the cast yields null:\n  %s"
		% "\n  ".join(wrong)).is_empty()


func test_the_dialog_nodes_really_are_windows() -> void:
	var controller: Node = load(CONTROLLER_SCENE).instantiate()
	auto_free(controller)

	var not_windows: Array[String] = []
	for path_name in ["exitGameHudPath", "helpDialogPath", "inGameMenuPath"]:
		var node_path: NodePath = controller.get(path_name)
		var node := controller.get_node_or_null(node_path)
		if node == null or not (node is Window):
			not_windows.append("%s -> %s" % [path_name, str(node)])

	assert_array(not_windows).override_failure_message(
		"Expected every dialog path to point at a Window: %s" % str(not_windows)).is_empty()
