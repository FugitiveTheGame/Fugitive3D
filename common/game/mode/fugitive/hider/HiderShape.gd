extends "res://common/game/player/PlayerShape.gd"

var standingMaterial = null
var crouchingMaterial = null

var alpha := 1.0: set = set_alpha
func set_alpha(value: float):
	alpha = value
	
	update_shaders()


func _ready():
	standingMaterial = $Standing/hider_standing.material_override
	crouchingMaterial = $Crouching/hider_crouching.material_override


func update_shaders():
	standingMaterial.set_shader_parameter("alpha", alpha)
	crouchingMaterial.set_shader_parameter("alpha", alpha)


func get_frozen_shape() -> Node3D:
	return $FrozenIce as Node3D
