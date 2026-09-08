extends GdUnitTestSuite

# viewport_2d_in_3d_body.gd pushes a touch event AND a mouse event for every
# pointer press. With emulate_mouse_from_touch left on, the touch becomes a
# second mouse press, so a dropdown opens and instantly closes again. The VR
# client turns emulation off for exactly this reason.
const PANEL_SIZE := Vector2i(1600, 900)
const DIALOG := "res://client/main_menu/vr/SettingsDialog.tscn"

var _panel: SubViewport
var _dialog: Window
var _emulation_was: bool


func before_test() -> void:
	_emulation_was = Input.is_emulating_mouse_from_touch()

	_panel = SubViewport.new()
	_panel.size = PANEL_SIZE
	_panel.gui_embed_subwindows = true
	_panel.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_panel)
	auto_free(_panel)

	_dialog = load(DIALOG).instantiate() as Window
	_panel.add_child(_dialog)
	_dialog.popup_centered()
	await await_idle_frame()


func after_test() -> void:
	Input.set_emulate_mouse_from_touch(_emulation_was)


func _dropdowns() -> Array:
	var found := []
	for child in _dialog.get_node("VBoxContainer").get_children():
		if child is OptionButton:
			found.append(child)
	return found


# One laser-pointer click. send_touch mirrors the addon's current behaviour of
# emitting a touch event alongside the mouse event for the same press.
func _vr_click(at: Vector2, send_touch: bool) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	_panel.push_input(motion)
	await await_idle_frame()

	for pressed in [true, false]:
		if send_touch:
			var touch := InputEventScreenTouch.new()
			touch.index = 0
			touch.position = at
			touch.pressed = pressed
			_panel.push_input(touch)

		var mouse := InputEventMouseButton.new()
		mouse.button_index = MOUSE_BUTTON_LEFT
		mouse.pressed = pressed
		mouse.position = at
		mouse.global_position = at
		mouse.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		_panel.push_input(mouse)
		await await_idle_frame()


func _click_each_dropdown(send_touch: bool) -> Array[String]:
	var dead: Array[String] = []
	for entry in _dropdowns():
		var button: OptionButton = entry
		# Off-headset there is no XR interface, so the refresh rate control
		# hides itself; an invisible node cannot be clicked either way
		if not button.visible:
			continue
		var popup: PopupMenu = button.get_popup()
		popup.hide()
		await await_idle_frame()

		var centre: Vector2 = Vector2(_dialog.position) + button.get_global_rect().get_center()
		await _vr_click(centre, send_touch)
		if not popup.visible:
			dead.append(str(button.name))

		popup.hide()
		await await_idle_frame()
	return dead


func test_mouse_only_click_opens_every_dropdown() -> void:
	var dead := await _click_each_dropdown(false)

	assert_array(dead).override_failure_message(
		"A single-press VR click does not open: %s" % str(dead)).is_empty()


# Guards the diagnosis: the duplicate press is what swallows the click
func test_touch_alongside_mouse_swallows_the_click() -> void:
	var dead := await _click_each_dropdown(true)

	assert_array(dead).override_failure_message(
		"A duplicate press no longer breaks dropdowns, so the panel need not send one press"
		).is_not_empty()

