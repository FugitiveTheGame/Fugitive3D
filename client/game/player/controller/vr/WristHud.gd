extends Node3D

# Wrist-mounted HUD: a quad showing a SubViewport that holds the HUD controls.
# The pointer (UiRaycast) forwards aim and clicks here, and they are injected
# into the viewport as mouse events so plain Controls and embedded Windows work.

@onready var viewport := $HudViewport as SubViewport
@onready var screen := $Screen as MeshInstance3D
@onready var screenBody := $ScreenBody as StaticBody3D

var _last_position := Vector2.ZERO


func _ready():
	var material := screen.material_override as StandardMaterial3D
	material.albedo_texture = viewport.get_texture()


func is_screen_body(body: Node) -> bool:
	return body == screenBody


func global_to_viewport(point: Vector3) -> Vector2:
	var local: Vector3 = screen.global_transform.affine_inverse() * point
	var quad := screen.mesh as QuadMesh
	var u := (local.x / quad.size.x) + 0.5
	var v := 0.5 - (local.y / quad.size.y)
	return Vector2(u, v) * Vector2(viewport.size)


func pointer_moved(point: Vector3):
	var position := global_to_viewport(point)
	var event := InputEventMouseMotion.new()
	event.position = position
	event.global_position = position
	event.relative = position - _last_position
	_last_position = position
	viewport.push_input(event)


func pointer_button(point: Vector3, pressed: bool):
	var position := global_to_viewport(point)
	var event := InputEventMouseButton.new()
	event.position = position
	event.global_position = position
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	_last_position = position
	viewport.push_input(event)
