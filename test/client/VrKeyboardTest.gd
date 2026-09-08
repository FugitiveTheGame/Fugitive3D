extends GdUnitTestSuite

# A headset has no system keyboard, so the VR panels carry their own. It has to
# follow focus into whichever text field the pointer clicked and type into it.

const UI_PANEL := "res://client/vr_menu_player/UiPanel3D.tscn"

var viewport: SubViewport
var field: LineEdit
var keyboard: VrKeyboard


func before_test() -> void:
	viewport = SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	add_child(viewport)

	field = LineEdit.new()
	viewport.add_child(field)

	keyboard = VrKeyboard.new()
	viewport.add_child(keyboard)
	await _settle()


func after_test() -> void:
	viewport.queue_free()
	await _settle()


# Focus is picked up in _process and keys are queued, so both need a frame to
# land before anything is asserted
func _settle() -> void:
	await get_tree().process_frame
	await get_tree().process_frame


func _key(label: String) -> Button:
	return _find_key(keyboard, label)


func _find_key(node: Node, label: String) -> Button:
	for child in node.get_children():
		if child is Button and (child as Button).text == label:
			return child as Button
		var found := _find_key(child, label)
		if found != null:
			return found
	return null


func _press(label: String) -> void:
	var key := _key(label)
	assert_object(key).override_failure_message("No '%s' key" % label).is_not_null()
	key.pressed.emit()
	await _settle()


func test_the_keyboard_stays_hidden_until_a_field_takes_focus() -> void:
	assert_bool(keyboard.visible).is_false()

	field.grab_focus()
	await _settle()

	assert_bool(keyboard.visible).is_true()

	field.release_focus()
	await _settle()

	assert_bool(keyboard.visible).is_false()


func test_keys_type_into_the_focused_field() -> void:
	field.grab_focus()
	await _settle()

	await _press("q")
	await _press("t")

	assert_str(field.text).is_equal("qt")


func test_shift_types_one_upper_case_letter() -> void:
	field.grab_focus()
	await _settle()

	await _press("Shift")
	await _press("Q")
	await _press("t")

	assert_str(field.text).is_equal("Qt")


func test_backspace_and_space_reach_the_field() -> void:
	field.grab_focus()
	await _settle()

	await _press("q")
	await _press("Space")
	await _press("t")
	await _press("Back")

	assert_str(field.text).is_equal("q ")


func test_the_symbol_page_swaps_the_letter_keys() -> void:
	field.grab_focus()
	await _settle()

	await _press("?123")
	assert_object(_key("q")).is_null()

	await _press("@")

	assert_str(field.text).is_equal("@")


func test_the_keys_never_steal_focus_from_the_field() -> void:
	field.grab_focus()
	await _settle()

	await _press("q")

	assert_bool(field.has_focus()).is_true()
	assert_bool(keyboard.visible).is_true()


func test_the_field_no_longer_asks_for_the_platform_keyboard() -> void:
	assert_bool(field.virtual_keyboard_enabled).is_false()


func test_every_vr_panel_carries_a_keyboard() -> void:
	var panel := (load(UI_PANEL) as PackedScene).instantiate()
	add_child(panel)
	await _settle()

	var found: Array = panel.viewport.find_children("*", "VrKeyboard", true, false)
	assert_int(found.size()).is_equal(1)

	panel.queue_free()
	await _settle()


func test_the_keyboard_moves_off_a_field_it_would_bury() -> void:
	field.position = Vector2(0, 60)
	field.size = Vector2(200, 40)
	field.grab_focus()
	await _settle()

	assert_float(keyboard.position.y).is_greater(400.0)

	field.release_focus()
	await _settle()
	field.position = Vector2(0, 820)
	field.grab_focus()
	await _settle()

	assert_float(keyboard.position.y).is_equal(0.0)
