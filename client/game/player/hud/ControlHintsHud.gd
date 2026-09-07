extends Control
class_name ControlHintsHud

# Edge-of-screen prompts for the actions available right now, PUBG style.
# The controller feeds it hints built by InputHintUtils; this only draws them
# and swaps between keyboard and gamepad prompts as the player switches device.

@export var rowsPath: NodePath
@onready var rows := get_node(rowsPath) as VBoxContainer

const CHIP_BACKGROUND := Color(0.113725, 0.121569, 0.180392, 0.8)
const CHIP_BORDER := Color(0.203922, 0.235294, 0.423529, 1)
const CHIP_TEXT := Color(0.87, 0.9, 1.0, 1)
const LABEL_TEXT := Color(0.87, 0.9, 1.0, 0.85)
const SHADOW := Color(0, 0, 0, 0.7)
const FONT_SIZE := 14
const CHIP_MINIMUM_WIDTH := 56
const CHIP_NAME := "Chip"

var device: int = InputHintUtils.Device.Keyboard

var hints: Array = []
var drawn_signature := ""

var chip_style: StyleBoxFlat


func _ready():
	chip_style = build_chip_style()
	UserData.user_data_updated.connect(update_visibility)
	update_visibility()


func build_chip_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = CHIP_BACKGROUND
	style.border_color = CHIP_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	return style


static func is_supported() -> bool:
	if PlatformTypeUtils.get_platform_category() != PlatformTypeUtils.PlatformCategory.Flat:
		return false
	# Mobile already has the actions as on-screen buttons
	return not DisplayServer.is_touchscreen_available()


static func is_enabled() -> bool:
	return is_supported() and UserData.data.on_screen_controls


func update_visibility():
	visible = is_enabled()


func set_hints(new_hints: Array):
	hints = new_hints
	redraw()


func _input(event: InputEvent):
	if not visible:
		return

	var event_device := InputHintUtils.device_for_event(event)
	if event_device >= 0 and event_device != device:
		device = event_device
		redraw()


func redraw():
	var signature := build_signature()
	if signature == drawn_signature:
		return
	drawn_signature = signature

	for index in hints.size():
		if index >= rows.get_child_count():
			rows.add_child(build_row())
		fill_row(rows.get_child(index), hints[index])

	# Rows are reused rather than rebuilt, so the surplus is only hidden
	for index in range(hints.size(), rows.get_child_count()):
		rows.get_child(index).hide()


func build_signature() -> String:
	var parts := PackedStringArray([str(device)])
	for hint_data in hints:
		parts.append("%s=%s" % [InputHintUtils.hint_prompt(hint_data, device), InputHintUtils.hint_label(hint_data)])
	return "|".join(parts)


func build_row() -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var chip := PanelContainer.new()
	chip.name = CHIP_NAME
	chip.add_theme_stylebox_override("panel", chip_style)
	chip.custom_minimum_size = Vector2(CHIP_MINIMUM_WIDTH, 0)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(build_label(HORIZONTAL_ALIGNMENT_CENTER, CHIP_TEXT))

	row.add_child(chip)
	row.add_child(build_label(HORIZONTAL_ALIGNMENT_LEFT, LABEL_TEXT))

	return row


func build_label(alignment: HorizontalAlignment, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	# The hints sit over whatever the player is looking at, street lights included
	label.add_theme_color_override("font_shadow_color", SHADOW)
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func fill_row(row: Control, hint_data: Dictionary):
	prompt_label(row).text = InputHintUtils.hint_prompt(hint_data, device)
	description_label(row).text = InputHintUtils.hint_label(hint_data)
	row.show()


static func prompt_label(row: Control) -> Label:
	return row.get_node(CHIP_NAME).get_child(0) as Label


static func description_label(row: Control) -> Label:
	return row.get_child(1) as Label
