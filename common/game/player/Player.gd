extends Spatial

const SPEED := 50.0

export(NodePath) var shapePath: NodePath
export(NodePath) var playerControllerPath: NodePath

var playerController: Spatial

func _ready():
	playerController = get_node(playerControllerPath)


puppet func network_update(networkPosition: Vector3, networkRotation: Vector3):
	playerController.translation = networkPosition
	playerController.rotation = networkRotation


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
	var shape := get_node(shapePath)
	var visibleShape = shape.get_visible_shape()
	visibleShape.hide()
	
