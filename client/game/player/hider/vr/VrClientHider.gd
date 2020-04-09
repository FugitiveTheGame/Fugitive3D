extends "res://client/game/player/controller/vr/VrPlayerController.gd"


func _process(delta):
	locomotion.allowMovement = not player.frozen
