extends CollisionShape3D

@onready var standing := $Standing as Node3D
@onready var crouching := $Crouching as Node3D
@onready var playerNameLabel := $PlayerNameLabel as Label3D


func get_name_label():
	return playerNameLabel


func get_standing_shape() -> Node3D:
	return standing


func get_crouching_shape() -> Node3D:
	return crouching


func set_crouching(is_crouching: bool):
	if is_crouching:
		get_standing_shape().hide()
		get_crouching_shape().show()
	else:
		get_standing_shape().show()
		get_crouching_shape().hide()
