extends Spatial


onready var cone := $Cone as MeshInstance
onready var material := cone.material_override as ShaderMaterial

var alpha: float setget set_alpha, get_alpha
func set_alpha(value: float):
	var albedo := material.get_shader_param("albedo") as Color
	albedo.a = value
	material.set_shader_param("albedo", albedo)
func get_alpha() -> float:
	return material.get_shader_param("albedo").a
