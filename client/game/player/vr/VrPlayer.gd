extends Spatial


func _physics_process(delta):
	if is_network_master():
		rpc_unreliable("network_update", $OQ_ARVROrigin.translation, $OQ_ARVROrigin.rotation)
