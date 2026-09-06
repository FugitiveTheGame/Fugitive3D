extends Node3D

# Wrist-mounted HUD: a quad showing a SubViewport that holds the HUD controls.
# The pointer (UiRaycast) forwards aim and clicks here, and they are injected
# into the viewport as mouse events so plain Controls and embedded Windows work.

@onready var viewport := $HudViewport as SubViewport
@onready var screen := $Screen as MeshInstance3D
@onready var screenBody := $ScreenBody as StaticBody3D

# The viewport only renders on request. The HUD controls poll their values
# every frame, so the screen is refreshed at a fixed rate instead of once per
# rendered frame.
const REFRESH_HZ := 30.0

var _last_position := Vector2.ZERO
var _refresh_accumulator := 0.0


func _ready():
	# The material is duplicated so panels never share an albedo texture
	var material := screen.material_override.duplicate() as StandardMaterial3D
	material.albedo_texture = viewport.get_texture()
	screen.material_override = material


func _process(delta):
	if not is_visible_in_tree():
		return
	_refresh_accumulator += delta
	if _refresh_accumulator >= 1.0 / REFRESH_HZ:
		_refresh_accumulator = fmod(_refresh_accumulator, 1.0 / REFRESH_HZ)
		refresh()


func refresh():
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE


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
	refresh()
