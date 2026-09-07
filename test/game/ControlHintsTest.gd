extends GdUnitTestSuite

# The hints read their prompts out of the InputMap, so an action renamed in
# project.godot turns every affected hint into "--" with no other symptom.
const HINTS_SCENE := "res://client/game/player/hud/ControlHintsHud.tscn"
const HINT_SCRIPTS := [
	"res://client/game/player/controller/flat/FlatPlayerController.gd",
	"res://client/game/mode/fugitive/FlatFugitiveController.gd",
	"res://client/game/mode/fugitive/seeker/flat/FlatSeekerController.gd",
]


func test_every_hinted_action_is_in_the_input_map() -> void:
	var unknown: Array[String] = []

	for path in HINT_SCRIPTS:
		var text := FileAccess.get_file_as_string(path)
		for action in hinted_actions(text):
			if not InputMap.has_action(action):
				unknown.append("%s hints at the unknown action %s" % [path.get_file(), action])

	assert_array(unknown).override_failure_message(
		"These hints have no action to read a key from:\n  %s" % "\n  ".join(unknown)).is_empty()


func hinted_actions(text: String) -> Array[String]:
	var actions: Array[String] = []
	var pattern := RegEx.create_from_string(r'InputHintUtils\.hint\("([^"]+)"')
	for found in pattern.search_all(text):
		actions.append(found.get_string(1))
	return actions


func test_keyboard_prompts_come_from_the_bound_key() -> void:
	assert_str(InputHintUtils.keyboard_prompt("flat_player_crouch")).is_equal("Ctrl")
	assert_str(InputHintUtils.keyboard_prompt("flat_player_sprint")).is_equal("Shift")
	assert_str(InputHintUtils.keyboard_prompt("flat_player_jump")).is_equal("Space")
	assert_str(InputHintUtils.keyboard_prompt("flat_player_use")).is_equal("E")


func test_gamepad_prompts_come_from_the_bound_button() -> void:
	assert_str(InputHintUtils.gamepad_prompt("flat_player_jump")).is_equal("A")
	assert_str(InputHintUtils.gamepad_prompt("flat_player_use")).is_equal("X")
	assert_str(InputHintUtils.gamepad_prompt("flat_player_sprint")).is_equal("LT")
	assert_str(InputHintUtils.gamepad_prompt("flat_player_crouch")).is_equal("RT")
	assert_str(InputHintUtils.gamepad_prompt("flat_fugitive_map")).is_equal("LB")


func test_an_unbound_action_reads_as_unbound() -> void:
	assert_str(InputHintUtils.keyboard_prompt("no_such_action")).is_equal(InputHintUtils.UNBOUND)
	assert_str(InputHintUtils.gamepad_prompt("no_such_action")).is_equal(InputHintUtils.UNBOUND)


func test_held_actions_say_so() -> void:
	assert_str(InputHintUtils.hint_label(InputHintUtils.hint("flat_fugitive_map", "Map", true))).is_equal("Map (hold)")
	assert_str(InputHintUtils.hint_label(InputHintUtils.hint("flat_player_jump", "Jump"))).is_equal("Jump")


func test_composites_switch_prompt_with_the_device() -> void:
	var move := InputHintUtils.composite("WASD", "Left Stick", "Move")
	assert_str(InputHintUtils.hint_prompt(move, InputHintUtils.Device.Keyboard)).is_equal("WASD")
	assert_str(InputHintUtils.hint_prompt(move, InputHintUtils.Device.Gamepad)).is_equal("Left Stick")


func test_gamepad_input_switches_the_prompts() -> void:
	var hints := build_hud()
	hints.set_hints([InputHintUtils.hint("flat_player_jump", "Jump")])
	assert_str(row_text(hints)).is_equal("Space Jump")

	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_A
	button.pressed = true
	hints._input(button)

	assert_str(row_text(hints)).is_equal("A Jump")


func test_mouse_motion_leaves_the_prompts_alone() -> void:
	var hints := build_hud()
	hints.device = InputHintUtils.Device.Gamepad
	hints.set_hints([InputHintUtils.hint("flat_player_jump", "Jump")])

	hints._input(InputEventMouseMotion.new())

	assert_str(row_text(hints)).is_equal("A Jump")


func test_a_shorter_hint_list_drops_the_surplus_rows() -> void:
	var hints := build_hud()
	hints.set_hints([
		InputHintUtils.hint("flat_player_jump", "Jump"),
		InputHintUtils.hint("flat_player_use", "Enter Car"),
	])
	hints.set_hints([InputHintUtils.hint("flat_player_jump", "Jump")])

	assert_str(row_text(hints)).is_equal("Space Jump")


func build_hud() -> ControlHintsHud:
	var hints := load(HINTS_SCENE).instantiate() as ControlHintsHud
	add_child(hints)
	auto_free(hints)
	# The platform gate would otherwise leave it hidden and deaf to input
	hints.visible = true
	return hints


func row_text(hints: ControlHintsHud) -> String:
	var text := PackedStringArray()
	for row in hints.rows.get_children():
		if not row.visible:
			continue
		text.append(ControlHintsHud.prompt_label(row).text)
		text.append(ControlHintsHud.description_label(row).text)
	return " ".join(text)
