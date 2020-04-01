extends Spatial

var isOn := false

puppet func network_update(networkPosition: Vector3, networkRotation: Vector3, networkOn: bool):
	translation = networkPosition
	rotation = networkRotation
	isOn = networkOn


func _physics_process(delta):
	if is_network_master():
		rpc_unreliable("network_update", translation, rotation, isOn)
