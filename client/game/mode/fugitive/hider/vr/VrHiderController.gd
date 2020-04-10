extends "res://client/game/mode/fugitive/VrFugitiveController.gd"

func _ready():
	player.set_is_local_player()


func _process(delta):
	locomotion.allowMovement = not player.frozen
