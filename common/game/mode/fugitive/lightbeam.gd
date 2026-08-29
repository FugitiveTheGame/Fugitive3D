extends Node3D


@onready var cone := $Cone as MeshInstance3D
@onready var material := cone.material_override as ShaderMaterial

var alpha: float: get = get_alpha, set = set_alpha
func set_alpha(value: float):
	var albedo := material.get_shader_parameter("albedo") as Color
	albedo.a = value
	material.set_shader_parameter("albedo", albedo)
func get_alpha() -> float:
	return material.get_shader_parameter("albedo").a
