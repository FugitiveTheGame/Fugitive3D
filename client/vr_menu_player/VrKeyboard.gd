extends PanelContainer
class_name VrKeyboard

# On-screen keyboard for the VR panels. A headset has no system keyboard to
# offer, so a text field that takes focus inside a panel viewport gets this one
# docked to the bottom of whichever viewport owns it, embedded dialog windows
# included. Keys are pushed straight into that viewport, so the field receives
# them the same way it would from a real keyboard.

# Fraction of the viewport height the keyboard is allowed to cover
const HEIGHT_RATIO := 0.42
const MAX_HEIGHT := 330.0
const KEY_GAP := 6

enum Page { LOWER, UPPER, SYMBOL }

# One entry per Page, and every row must be the same length across pages so a
# page swap is just a relabel of the keys already built
const PAGES := [
	["1234567890", "qwertyuiop", "asdfghjkl", "zxcvbnm"],
	["1234567890", "QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"],
	["1234567890", "-_=+[]{}|@", ";:'\"`~/?\\", "!#$%^&*"],
]

# The row shift and backspace sit on
const MODIFIER_ROW := 3

var _page: int = Page.LOWER
var _target: Control
var _root: Viewport
var _char_keys: Array[Array] = []
var _shift_key: Button
var _symbol_key: Button


func _ready():
	_root = get_viewport()
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()
	_silence_system_keyboard(_root)


func _process(_delta):
	var focused := _focused_field()
	if focused == _target:
		return

	_target = focused
	if _target == null:
		visible = false
		_attach_to(_root)
		return

	_attach_to(_target.get_viewport())
	visible = true


# Every viewport a field could hold focus in, dialogs first so an open one wins
func _input_viewports() -> Array[Viewport]:
	var found: Array[Viewport] = []
	_collect_windows(_root, found)
	found.append(_root)
	return found


func _collect_windows(node: Node, found: Array[Viewport]) -> void:
	for child in node.get_children():
		if child is Window:
			if not (child as Window).visible:
				continue
			found.append(child as Window)
		_collect_windows(child, found)


func _focused_field() -> Control:
	for viewport in _input_viewports():
		var focused := viewport.gui_get_focus_owner()
		if focused is LineEdit or focused is TextEdit:
			return focused
	return null


func _attach_to(viewport: Viewport) -> void:
	if get_parent() != viewport:
		get_parent().remove_child(self)
		viewport.add_child(self)
	else:
		viewport.move_child(self, -1)
	_dock()


# The keyboard sits along the bottom, and moves to the top when that would
# bury the field being typed into
func _dock() -> void:
	var area := get_viewport().get_visible_rect().size
	var height: float = min(area.y * HEIGHT_RATIO, MAX_HEIGHT)
	var top := area.y - height
	if _target != null and _target.get_global_rect().end.y > top:
		top = 0.0

	anchor_left = 0.0
	anchor_right = 1.0
	anchor_top = 0.0
	anchor_bottom = 0.0
	offset_left = 0.0
	offset_right = 0.0
	offset_top = top
	offset_bottom = top + height


# Godot pops the platform's own keyboard when a field takes focus, and on a
# headset that lands somewhere the player cannot see
func _silence_system_keyboard(node: Node) -> void:
	if node is LineEdit:
		(node as LineEdit).virtual_keyboard_enabled = false
	elif node is TextEdit:
		(node as TextEdit).virtual_keyboard_enabled = false

	for child in node.get_children():
		_silence_system_keyboard(child)


func _build() -> void:
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", KEY_GAP)
	add_child(rows)

	var layout: Array = PAGES[Page.LOWER]
	for index in layout.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", KEY_GAP)
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		rows.add_child(row)

		if index == MODIFIER_ROW:
			_shift_key = _command_key("Shift", _toggle_shift, 1.6)
			_shift_key.toggle_mode = true
			row.add_child(_shift_key)

		var keys: Array = []
		for character in (layout[index] as String):
			var key := _char_key(character)
			row.add_child(key)
			keys.append(key)
		_char_keys.append(keys)

		if index == MODIFIER_ROW:
			row.add_child(_command_key("Back", _backspace, 1.6))

	rows.add_child(_build_bottom_row())


func _build_bottom_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", KEY_GAP)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_symbol_key = _command_key("?123", _toggle_symbols, 1.6)
	row.add_child(_symbol_key)
	row.add_child(_char_key(","))
	row.add_child(_command_key("Space", _type_space, 5.0))
	row.add_child(_char_key("."))
	row.add_child(_command_key("Enter", _submit, 1.6))
	row.add_child(_command_key("Done", _dismiss, 1.6))
	return row


func _char_key(character: String) -> Button:
	var key := _new_key(character, 1.0)
	key.pressed.connect(_on_char_key_pressed.bind(key))
	return key


func _command_key(label: String, handler: Callable, stretch: float) -> Button:
	var key := _new_key(label, stretch)
	key.pressed.connect(handler)
	return key


func _new_key(label: String, stretch: float) -> Button:
	var key := Button.new()
	key.text = label
	# A key must never take focus away from the field it is typing into
	key.focus_mode = Control.FOCUS_NONE
	key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	key.size_flags_stretch_ratio = stretch
	return key


func _on_char_key_pressed(key: Button) -> void:
	_type(key.text)
	if _page == Page.UPPER:
		_set_page(Page.LOWER)


func _type(character: String) -> void:
	if character.is_empty():
		return

	var event := InputEventKey.new()
	event.pressed = true
	event.unicode = character.unicode_at(0)
	event.shift_pressed = _page == Page.UPPER
	_send(event)


func _type_space() -> void:
	_type(" ")


func _backspace() -> void:
	_send_keycode(KEY_BACKSPACE)


func _submit() -> void:
	_send_keycode(KEY_ENTER)


func _dismiss() -> void:
	if _target != null:
		_target.release_focus()


func _send_keycode(keycode: Key) -> void:
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	event.physical_keycode = keycode
	_send(event)


# Keys are pressed from inside the viewport's own input handling, so the event
# is queued rather than pushed back into the middle of that
func _send(event: InputEventKey) -> void:
	if _target == null:
		return

	var viewport := _target.get_viewport()
	if viewport == null:
		return

	viewport.push_input.call_deferred(event)


func _toggle_shift() -> void:
	_set_page(Page.LOWER if _page == Page.UPPER else Page.UPPER)


func _toggle_symbols() -> void:
	_set_page(Page.LOWER if _page == Page.SYMBOL else Page.SYMBOL)


func _set_page(page: int) -> void:
	_page = page

	var layout: Array = PAGES[_page]
	for row_index in _char_keys.size():
		var characters: String = layout[row_index]
		var keys: Array = _char_keys[row_index]
		for key_index in keys.size():
			(keys[key_index] as Button).text = characters[key_index]

	_shift_key.button_pressed = _page == Page.UPPER
	_symbol_key.text = "ABC" if _page == Page.SYMBOL else "?123"
