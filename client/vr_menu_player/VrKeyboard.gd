extends Node3D
class_name VrKeyboard

# Shows the XR Tools keyboard for as long as a text field on a menu panel holds
# focus. A headset offers no system keyboard: core OpenXR has none, the vendors
# plugin does not carry Meta's extension, and Godot's own call raises the
# Android IME where the player cannot see it.
#
# XR Tools types by firing key events into the global input queue, which
# Viewport2Din3D forwards into its own viewport. That queue is dead to a panel
# whenever a popup has grabbed input, which is every dialog in these menus, so
# the keys are taken off the keyboard directly and handed to the viewport that
# owns the field instead.

## Panel whose text fields this keyboard types into
@export var panelPath: NodePath

@onready var panel := get_node(panelPath) as XRToolsViewport2DIn3D
@onready var keyboard := $Keyboard as XRToolsViewport2DIn3D


func _ready():
	keyboard.visible = false

	# This keyboard delivers its own keys, so the panel must not also forward
	# them and type everything twice
	panel.input_keyboard = false
	_connect_keys(keyboard.get_scene_instance())

	_silence_system_keyboard.call_deferred(_panel_viewport())


func _process(_delta):
	keyboard.visible = focused_field() != null


func _connect_keys(node: Node) -> void:
	if node is XRToolsVirtualKeyChar:
		var key := node as XRToolsVirtualKeyChar
		key.pressed.connect(_on_key_pressed.bind(key))

	for child in node.get_children():
		_connect_keys(child)


# Keys are pressed from inside a viewport's own input handling, so the event is
# queued rather than pushed back into the middle of that
func _on_key_pressed(key: XRToolsVirtualKeyChar) -> void:
	var field := focused_field()
	if field == null:
		return

	var keycode := OS.find_keycode_from_string(key.scan_code_text)
	var event := InputEventKey.new()
	event.pressed = true
	event.keycode = keycode
	event.physical_keycode = keycode
	event.unicode = key.unicode if key.unicode else keycode
	event.shift_pressed = key.shift_modifier
	field.get_viewport().push_input.call_deferred(event)


func _panel_viewport() -> Viewport:
	return panel.get_node("Viewport") as Viewport


## The text field currently being typed into, or null when there is none
func focused_field() -> Control:
	for viewport in _input_viewports():
		var focused := viewport.gui_get_focus_owner()
		if focused is LineEdit or focused is TextEdit:
			return focused

	return null


# Every viewport a field could hold focus in, dialogs first so an open one wins
func _input_viewports() -> Array[Viewport]:
	var root := _panel_viewport()
	var found: Array[Viewport] = []
	_collect_windows(root, found)
	found.append(root)
	return found


func _collect_windows(node: Node, found: Array[Viewport]) -> void:
	for child in node.get_children():
		if child is Window:
			if not (child as Window).visible:
				continue
			found.append(child as Window)
		_collect_windows(child, found)


# Godot raises the platform's own keyboard when a field takes focus, and on a
# headset that lands somewhere the player cannot see
func _silence_system_keyboard(node: Node) -> void:
	if node is LineEdit:
		(node as LineEdit).virtual_keyboard_enabled = false
	elif node is TextEdit:
		(node as TextEdit).virtual_keyboard_enabled = false

	for child in node.get_children():
		_silence_system_keyboard(child)
