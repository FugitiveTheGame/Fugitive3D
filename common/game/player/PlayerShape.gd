extends CollisionShape

onready var standing := $Standing as Spatial
onready var crouching := $Crouching as Spatial
onready var playerNameLabel := $PlayerNameLabel as Spatial

func _ready():
	get_name_label().transparent = not Utils.renderer_is_gles2()


func get_name_label():
	return playerNameLabel


func get_standing_shape() -> Spatial:
	return standing


func get_crouching_shape() -> Spatial:
	return crouching


func set_crouching(is_crouching: bool):
	if is_crouching:
		get_standing_shape().hide()
		get_crouching_shape().show()
	else:
		get_standing_shape().show()
		get_crouching_shape().hide()
