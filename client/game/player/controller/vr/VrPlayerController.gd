extends "res://addons/OQ_Toolkit/OQ_ARVROrigin/scripts/OQ_ARVROrigin.gd"


func _physics_process(delta):
	$Player.rpc_unreliable("network_update", translation, rotation, $Player.is_crouching)
