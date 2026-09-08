extends GdUnitTestSuite

# A headset offers no system keyboard, so the VR menus carry the XR Tools one.
# It has to appear for whichever text field the pointer clicked, and its keys
# have to reach that field through the panel the menu is rendered on.

const VR_MAIN_MENU := "res://client/main_menu/vr/VrClientMainMenu.tscn"
const VR_LOBBY := "res://client/lobby/vr/VrLobby.tscn"

var menu: Node3D
var panel: XRToolsViewport2DIn3D
var vrKeyboard: VrKeyboard
var playerName: LineEdit


func before_test() -> void:
	menu = (load(VR_MAIN_MENU) as PackedScene).instantiate()
	add_child(menu)
	await _settle()

	panel = menu.get_node("MainMenuDisplay")
	vrKeyboard = menu.get_node("MainMenuDisplay/VrKeyboard")
	playerName = panel.get_node(
		"Viewport/MainMenu/VBoxContainer/UsernamePanel/VBoxContainer/PlayerName")


func after_test() -> void:
	menu.queue_free()
	await _settle()


# Focus is picked up in _process and keys travel through the input queue, so
# both need a frame to land before anything is asserted
func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _keyboard_2d() -> XRToolsVirtualKeyboard2D:
	return vrKeyboard.keyboard.get_scene_instance() as XRToolsVirtualKeyboard2D


func _press(scan_code_text: String) -> void:
	var key := _find_key(_keyboard_2d(), scan_code_text)
	assert_object(key).override_failure_message(
		"No '%s' key on the keyboard" % scan_code_text).is_not_null()
	key.pressed.emit()
	await _settle()


func _find_key(node: Node, scan_code_text: String) -> XRToolsVirtualKeyChar:
	for child in node.get_children():
		if child is XRToolsVirtualKeyChar:
			var key := child as XRToolsVirtualKeyChar
			if key.scan_code_text == scan_code_text and key.visible:
				return key
		var found := _find_key(child, scan_code_text)
		if found != null:
			return found
	return null


func test_the_menu_renders_inside_the_panel_viewport() -> void:
	assert_object(playerName).is_not_null()
	assert_object(panel.get_scene_instance()).is_not_null()


func test_the_keyboard_stays_hidden_until_a_field_takes_focus() -> void:
	assert_bool(vrKeyboard.keyboard.visible).is_false()

	playerName.grab_focus()
	await _settle()

	assert_bool(vrKeyboard.keyboard.visible).is_true()

	playerName.release_focus()
	await _settle()

	assert_bool(vrKeyboard.keyboard.visible).is_false()


func test_keys_reach_the_focused_field() -> void:
	playerName.clear()
	playerName.grab_focus()
	await _settle()

	await _press("Q")
	await _press("7")

	assert_str(playerName.text).is_equal("q7")


# The dialogs are popped up, not merely shown, and a popup grabs input away
# from the global queue XR Tools types into
func test_keys_reach_a_field_in_a_popped_up_dialog() -> void:
	var feedback := panel.get_node("Viewport/MainMenu/FeedbackDialog") as Window
	feedback.popup_centered()
	await _settle()

	var userName := feedback.get_node("Container/UserNameEdit") as LineEdit
	userName.clear()
	userName.grab_focus()
	await _settle()

	assert_object(vrKeyboard.focused_field()).is_same(userName)
	assert_bool(vrKeyboard.keyboard.visible).is_true()

	await _press("Q")
	await _press("7")

	assert_str(userName.text).is_equal("q7")


func test_a_key_types_once_and_only_once() -> void:
	playerName.clear()
	playerName.grab_focus()
	await _settle()

	await _press("Q")

	assert_str(playerName.text).is_equal("q")


func test_the_fields_no_longer_ask_for_the_platform_keyboard() -> void:
	assert_bool(playerName.virtual_keyboard_enabled).is_false()

	var serverIp := panel.get_node(
		"Viewport/MainMenu/ManualContainer/VBoxContainer/HBoxContainer/ServerIp") as LineEdit
	assert_bool(serverIp.virtual_keyboard_enabled).is_false()


func test_the_pointer_and_the_panel_share_a_collision_layer() -> void:
	var pointer := menu.get_node(
		"VrMenuPlayer/Origin/RightHand/FunctionPointer") as XRToolsFunctionPointer
	var body := panel.get_node("StaticBody3D") as StaticBody3D

	assert_int(pointer.collision_mask & body.collision_layer).is_not_equal(0)


func test_the_vr_lobby_keeps_its_voice_chat_container() -> void:
	var lobby := (load(VR_LOBBY) as PackedScene).instantiate()
	add_child(lobby)
	await _settle()

	var ui := lobby.get_node("LobbyMenuDisplay/Viewport/Lobby")
	assert_object(ui.voiceChatContainer).is_same(lobby.get_node("VoiceChatContainer"))

	lobby.queue_free()
	await _settle()
