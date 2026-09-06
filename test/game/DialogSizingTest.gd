extends GdUnitTestSuite

# Window derives from Viewport and is sized by "size", not anchors. A dialog
# with anchors but no size falls back to Godot's 100x100 default and clips.
const DIALOGS := [
	"res://client/game/mode/fugitive/hud/InGameMenuHud.tscn",
	"res://client/game/mode/fugitive/hud/ExitGameHud.tscn",
	"res://client/HelpDialog.tscn",
	"res://client/main_menu/flat/SettingsDialog.tscn",
]

const GODOT_DEFAULT_WINDOW_SIZE := Vector2i(100, 100)


func test_dialogs_are_big_enough_for_their_contents() -> void:
	var clipped: Array[String] = []

	for path in DIALOGS:
		var window := load(path).instantiate() as Window
		auto_free(window)
		assert_object(window).override_failure_message(
			"%s is not a Window" % path).is_not_null()

		if window.size == GODOT_DEFAULT_WINDOW_SIZE:
			clipped.append("%s is still at Godot's default %s" % [
				path.get_file(), str(window.size)])
			continue

		for child in window.get_children():
			if child is Control:
				var needed: Vector2 = child.get_combined_minimum_size()
				if window.size.x < int(needed.x) or window.size.y < int(needed.y):
					clipped.append("%s is %s but its content needs %s" % [
						path.get_file(), str(window.size), str(needed)])
				break

	assert_array(clipped).override_failure_message(
		"These dialogs clip their own contents:\n  %s" % "\n  ".join(clipped)).is_empty()
