extends Control
class_name VirtualJoysticks

# The stick head is this much of its base across
const STICK_HEAD_RATIO := 0.5

@export var left_dead_zone := 0.40 # (float, 0.0, 1.0, 0.001)
@export var right_dead_zone := 0.40 # (float, 0.0, 1.0, 0.001)

@onready var baseLeft := $BaseLeft as TextureRect
@onready var baseRight := $BaseRight as TextureRect

@onready var stickLeft := $BaseLeft/Stick as TextureRect
@onready var stickRight := $BaseRight/Stick as TextureRect


var left_finger_index := -1
var right_finger_index := -1

var left_initial_position: Vector2
var right_initial_position: Vector2

var left_move_radius: float
var right_move_radius: float

var left_output := Vector2()
var right_output := Vector2()


func _ready():
	visible = DisplayServer.is_touchscreen_available()
	
	MobileUi.layout_changed.connect(layout)
	layout()


# Both sticks sit in the bottom corners of the safe area, sized off the design
# height so a thumb covers the same slice of screen on any phone
func layout():
	# Touches are matched against the base rects in this control's own space, so
	# it has to cover the whole screen for them to line up
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	var area := MobileUi.safe_area()
	var diameter := MobileUi.stick_diameter()
	var base_size := Vector2(diameter, diameter)
	
	place_base(baseLeft, base_size, Vector2(area.position.x, area.end.y - diameter))
	place_base(baseRight, base_size, Vector2(area.end.x - diameter, area.end.y - diameter))
	
	left_initial_position = place_stick(stickLeft, base_size)
	right_initial_position = place_stick(stickRight, base_size)
	
	left_move_radius = get_min_size(base_size) / 2.0
	right_move_radius = get_min_size(base_size) / 2.0


func place_base(base: TextureRect, base_size: Vector2, top_left: Vector2):
	base.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	base.stretch_mode = TextureRect.STRETCH_SCALE
	base.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	base.size = base_size
	base.position = top_left


func place_stick(stick: TextureRect, base_size: Vector2) -> Vector2:
	stick.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stick.stretch_mode = TextureRect.STRETCH_SCALE
	stick.set_anchors_preset(Control.PRESET_TOP_LEFT, false)
	stick.size = base_size * STICK_HEAD_RATIO
	stick.position = (base_size - stick.size) / 2.0
	return stick.position


func get_min_size(rect: Vector2) -> float:
	return min(rect.x, rect.y)


func _gui_input(event):
	handle_left(event)
	handle_right(event)
	
	if event is InputEventScreenDrag:
		if event.index == left_finger_index:
			left_output = update_stick(stickLeft, baseLeft, left_move_radius, left_initial_position, event.position, left_dead_zone)
		elif event.index == right_finger_index:
			right_output = update_stick(stickRight, baseRight, right_move_radius, right_initial_position, event.position, right_dead_zone)


func update_stick(stick: TextureRect, base: TextureRect, radius: float, centerPosition: Vector2, newPosition: Vector2, deadZone: float) -> Vector2:
	var stick_center := newPosition - base.position - (stick.size / 2.0)
	
	var output := Vector2()
	if centerPosition.distance_to(stick_center) > radius:
		var restricted := centerPosition + (stick_center - centerPosition).normalized() * radius
		output = restricted - centerPosition
		stick.set_position(restricted)
	else:
		output = stick_center - centerPosition
		stick.set_position(stick_center)
	
	output = output / radius
	
	if output.x < deadZone and output.x > -deadZone:
		output.x = 0.0
	
	if output.y < deadZone and output.y > -deadZone:
		output.y = 0.0
	else:
		output.y *= -1.0
	
	return output


func _unhandled_input(event):
	handle_left(event)
	handle_right(event)


func _on_BaseLeft_gui_input(event):
	handle_left(event)


func _on_BaseRight_gui_input(event):
	handle_right(event)


func handle_left(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			if baseLeft.get_rect().has_point(event.position):
				if left_finger_index == -1:
					left_finger_index = event.index
					print("capture LEFT")
		elif event.index == left_finger_index:
			release_left()
	elif event is InputEventScreenDrag:
		if left_finger_index == -1 and baseLeft.get_rect().has_point(event.position):
			left_finger_index = event.index
			print("capture LEFT")


func handle_right(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed:
			if baseRight.get_rect().has_point(event.position):
				if right_finger_index == -1:
					right_finger_index = event.index
					print("capture RIGHT")
		elif event.index == right_finger_index:
			release_right()
	elif event is InputEventScreenDrag:
		if right_finger_index == -1 and baseRight.get_rect().has_point(event.position):
			right_finger_index = event.index
			print("capture RIGHT")


func release_left():
	if left_finger_index > -1:
		print("release LEFT")
		left_finger_index = -1
		left_output = Vector2()
		stickLeft.position = left_initial_position


func release_right():
	if right_finger_index > -1:
		print("release RIGHT")
		right_finger_index = -1
		right_output = Vector2()
		stickRight.position = right_initial_position
