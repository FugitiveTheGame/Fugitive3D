extends "res://common/game/player/PlayerShape.gd"

var standingMaterial = null
var crouchingMaterial = null

var alpha := 1.0 setget set_alpha
func set_alpha(value: float):
	alpha = value
	
	update_shaders()


func _ready():
	standingMaterial = $Standing/hider_standing.material_override
	crouchingMaterial = $Crouching/hider_crouching.material_override


func update_shaders():
	standingMaterial.set_shader_param("alpha", alpha)
	crouchingMaterial.set_shader_param("alpha", alpha)


func get_frozen_shape() -> Spatial:
	return $FrozenIce as Spatial
