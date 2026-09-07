extends Node
class_name TouchControlsLayout

# Arranges the whole touchscreen HUD: the buttons into clusters around the two
# joysticks, and the status readouts up top where the thumbs are not.
#
# Everything is measured off the safe area and the design height rather than
# authored positions, so the controls land in the same place on any phone.

# Room left under the top-right corner for whatever the game mode puts there
const INDICATOR_TOP_INSET_RATIO := 0.02

@export var button_root_path: NodePath
@onready var button_root := get_node_or_null(button_root_path) as Node

@export var joysticks_path: NodePath
@onready var joysticks := get_node_or_null(joysticks_path) as VirtualJoysticks

# Stamina and car lock bars, moved off the movement stick
@export var bars_path: NodePath
@onready var bars := get_node_or_null(bars_path) as Control

# Crouching, frozen and voice icons, moved off the look stick
@export var indicators_path: NodePath
@onready var indicators := get_node_or_null(indicators_path) as Control

# The match clock, moved out of the top corner the indicators now use
@export var timer_path: NodePath
@onready var timer := get_node_or_null(timer_path) as Control

# The overview map draws itself to fill its own rect, so it only has to be
# given one that fits the screen
@export var map_path: NodePath
@onready var map := get_node_or_null(map_path) as Control


func _ready():
	MobileUi.layout_changed.connect(refresh)
	refresh.call_deferred()


func refresh():
	if not DisplayServer.is_touchscreen_available():
		return
	
	var area := MobileUi.safe_area()
	var gap := MobileUi.touch_gap()
	var height := MobileUi.touch_button_height()
	
	place_buttons(area, gap, height)
	place_readouts(area, gap, height)


func place_buttons(area: Rect2, gap: float, height: float):
	if button_root == null:
		return
	
	for slot in TouchControlButton.Slot.values():
		for row in rows_in_slot(slot):
			place_row(collect(slot, row), area, gap, height)


func rows_in_slot(slot: int) -> Array:
	var rows := {}
	for button in buttons():
		if button.slot == slot:
			rows[button.slot_row] = true
	return rows.keys()


func buttons() -> Array:
	var found: Array = []
	for child in button_root.get_children():
		if child is TouchControlButton:
			found.append(child)
	return found


func collect(slot: int, row: int) -> Array:
	var group: Array = []
	for button in buttons():
		if button.slot == slot and button.slot_row == row:
			group.append(button)
	group.sort_custom(func(a, b): return a.slot_column < b.slot_column)
	return group


func place_row(group: Array, area: Rect2, gap: float, height: float):
	if group.is_empty():
		return
	
	var slot: int = group[0].slot
	var row: int = group[0].slot_row
	var origin := cluster_origin(slot, area, gap)
	var towards := cluster_direction(slot)
	
	var top := origin.y + towards.y * row * (height + gap)
	if towards.y < 0.0:
		top -= height
	
	var cursor := origin.x
	for button in group:
		var size := button_size(button, height)
		button.position = Vector2(cursor if towards.x > 0.0 else cursor - size.x, top)
		button.scale = Vector2.ONE * (height / max(texture_size(button).y, 1.0))
		cursor += towards.x * (size.x + gap)


func cluster_origin(slot: int, area: Rect2, gap: float) -> Vector2:
	var stick := MobileUi.stick_diameter()
	
	match slot:
		TouchControlButton.Slot.TopLeft:
			return area.position
		TouchControlButton.Slot.TopRight:
			return Vector2(area.end.x, area.position.y)
		TouchControlButton.Slot.AboveLeftStick:
			return Vector2(area.position.x, area.end.y - stick - gap)
		_:
			return Vector2(area.end.x - stick - gap, area.end.y)


func cluster_direction(slot: int) -> Vector2:
	match slot:
		TouchControlButton.Slot.TopLeft:
			return Vector2(1.0, 1.0)
		TouchControlButton.Slot.TopRight:
			return Vector2(-1.0, 1.0)
		TouchControlButton.Slot.AboveLeftStick:
			return Vector2(1.0, -1.0)
		_:
			return Vector2(-1.0, -1.0)


static func texture_size(button: TouchScreenButton) -> Vector2:
	if button.texture_normal == null:
		return Vector2.ONE
	return button.texture_normal.get_size()


static func button_size(button: TouchScreenButton, height: float) -> Vector2:
	var texture := texture_size(button)
	return Vector2(height * (texture.x / max(texture.y, 1.0)), height)


func place_readouts(area: Rect2, gap: float, height: float):
	# The bars move up out of the movement stick, clear of the top left cluster
	if bars != null:
		var top_left_width := row_width(collect(TouchControlButton.Slot.TopLeft, 0), gap, height)
		pin(bars, Vector2(0.0, 0.0), Vector2(area.position.x + top_left_width, area.position.y))
	
	# The indicators move down out of the look stick
	if indicators != null:
		var inset := MobileUi.design_size().y * INDICATOR_TOP_INSET_RATIO
		pin(indicators, Vector2(1.0, 0.0), Vector2(area.end.x - indicators.size.x, area.position.y + inset))
	
	# The clock moves to the top middle, which no thumb has to reach across
	if timer != null:
		pin(timer, Vector2(0.5, 0.0), Vector2(area.get_center().x - timer.size.x / 2.0, area.position.y))
	
	if map != null:
		var side := minf(area.size.x, area.size.y)
		map.size = Vector2(side, side)
		pin(map, Vector2(0.5, 0.5), area.get_center() - map.size / 2.0)
		if map.has_method("update_map_background"):
			map.update_map_background()


func row_width(group: Array, gap: float, height: float) -> float:
	var width := 0.0
	for button in group:
		width += button_size(button, height).x + gap
	return width


# Fixes a control at a point in the design space, keeping the size it has
static func pin(control: Control, anchor: Vector2, top_left: Vector2):
	var kept := control.size
	
	control.anchor_left = anchor.x
	control.anchor_right = anchor.x
	control.anchor_top = anchor.y
	control.anchor_bottom = anchor.y
	
	var origin := control.get_parent_area_size() * anchor
	control.offset_left = top_left.x - origin.x
	control.offset_top = top_left.y - origin.y
	control.offset_right = control.offset_left + kept.x
	control.offset_bottom = control.offset_top + kept.y
