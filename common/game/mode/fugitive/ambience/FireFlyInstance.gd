extends OneTimeVisualEffect
class_name FireFlyInstance

var local_bounding_box := AABB()

signal fire_fly_complete(node)

onready var body_material := $Body.mesh.surface_get_material(0) as ShaderMaterial

export(float, 0.0, 1.0) var alpha_override setget set_alpha_override, get_alpha_override


func set_alpha_override(value: float):
	if body_material != null:
		body_material.set_shader_param("alpha_override", value)


func get_alpha_override() -> float:
	if body_material != null:
		return body_material.get_shader_param("alpha_override")
	else:
		return 0.0


func fire_fly_completed():
	emit_signal("fire_fly_complete", self)
