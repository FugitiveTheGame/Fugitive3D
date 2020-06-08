extends "res://common/game/player/PlayerShape.gd"

var standingMaterials = []
var crouchingMaterials = []

var alpha := 1.0 setget set_alpha
func set_alpha(value: float):
	alpha = value
	
	update_shaders()


func _ready():
	standingMaterials.append($Standing/hider_standing.material_override)
	crouchingMaterials.append($Crouching/hider_crouching.material_override)


func update_shaders():
	for material in standingMaterials:
		material.set_shader_param("alpha", alpha)
	
	for material in crouchingMaterials:
		material.set_shader_param("alpha", alpha)


func get_frozen_shape() -> Spatial:
	return $FrozenIce as Spatial
