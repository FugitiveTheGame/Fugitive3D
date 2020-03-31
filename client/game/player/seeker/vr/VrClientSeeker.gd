extends "res://client/game/player/controller/vr/VrPlayerController.gd"

func _ready():
	$Player.set_is_local_player()


func _physics_process(delta):
	$Player.rpc_unreliable("network_update", translation, rotation)
