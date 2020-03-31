extends "res://client/game/player/controller/PlayerController.gd"


func _physics_process(delta):
	if is_network_master():
		player.rpc_unreliable("network_update", $OQ_ARVROrigin.translation, $OQ_ARVROrigin.rotation)
