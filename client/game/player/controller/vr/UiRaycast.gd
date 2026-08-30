extends Node3D

# Controller laser pointer for the wrist HUD. While visible it casts along
# the controller aim, drives the laser beam visual, and forwards hover and
# trigger clicks to the WristHud it hits.

const LASER_MAX_LENGTH := 2.0

@export var hudPath: NodePath

@onready var hud := get_node(hudPath)
@onready var ray := $RayCast3D as RayCast3D
@onready var laser := $Laser as MeshInstance3D

var _controller: XRController3D
var _pressed := false
var _hovering := false


func _ready():
	_controller = get_parent() as XRController3D
	ray.target_position = Vector3(0.0, 0.0, -LASER_MAX_LENGTH)


func _physics_process(_delta):
	if not visible:
		if _pressed or _hovering:
			_pressed = false
			_hovering = false
		return

	ray.force_raycast_update()

	var hit_hud: bool = ray.is_colliding() and hud.is_screen_body(ray.get_collider())
	if hit_hud:
		var point := ray.get_collision_point()
		_set_laser_length(to_local(point).length())
		_hovering = true
		hud.pointer_moved(point)

		var now_pressed: bool = _controller != null and _controller.is_button_pressed("trigger_click")
		if now_pressed != _pressed:
			_pressed = now_pressed
			hud.pointer_button(point, now_pressed)
	else:
		_set_laser_length(LASER_MAX_LENGTH)
		_hovering = false
		if _pressed:
			_pressed = false


func _set_laser_length(length: float):
	laser.scale.z = length
	laser.position.z = -length * 0.5
