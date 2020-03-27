extends KinematicBody

const SPEED := 50.0


puppet func network_update(networkPosition: Vector3, networkRotation: Vector3):
	self.translation = networkPosition
	self.rotation = networkRotation


func set_player_name(playerName: String):
	#$NameLabel.text = playerName
	pass
