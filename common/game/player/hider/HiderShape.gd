extends "res://common/game/player/PlayerShape.gd"

var standingMaterials = []
var crouchingMaterials = []

var alpha := 1.0 setget set_alpha
func set_alpha(value: float):
	alpha = value
	
	update_shaders()


func _ready():
	standingMaterials.append($Standing/hider_standing_body/Cylinder.material_override)
	standingMaterials.append($Standing/head/Cube.material_override)
	standingMaterials.append($Standing/head/Sphere.material_override)
	
	crouchingMaterials.append($Crouching/hider_crouching_body/Cylinder.material_override)
	crouchingMaterials.append($Crouching/head/Cube.material_override)
	crouchingMaterials.append($Crouching/head/Sphere.material_override)


func update_shaders():
	for material in standingMaterials:
		material.set_shader_param("alpha", alpha)
	
	for material in crouchingMaterials:
		material.set_shader_param("alpha", alpha)
