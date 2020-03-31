extends KinematicBody

const SPEED := 50.0


puppet func network_update(networkPosition: Vector3, networkRotation: Vector3):
	self.translation = networkPosition
	self.rotation = networkRotation


func configure(playerName: String):
	set_player_name(playerName)


func set_not_local_player():
	print("set_not_local_player()")


func set_is_local_player():
	hide_avatar()


func set_player_name(playerName: String):
	#$NameLabel.text = playerName
	pass


func hide_avatar():
	$Avatar.hide()
