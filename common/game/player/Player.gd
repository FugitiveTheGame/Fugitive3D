extends Spatial

const SPEED := 50.0

var show_avatar := true
var is_crouching := false setget set_is_crouching
func set_is_crouching(value: bool):
	if value != is_crouching:
		is_crouching = value
		
		if show_avatar:
			playerShape.set_crouching(value)


export(NodePath) var shapePath: NodePath
export(NodePath) var playerControllerPath: NodePath
export(NodePath) var playerBodyPath: NodePath

onready var playerController := get_node(playerControllerPath) as Spatial
onready var playerShape := get_node(shapePath) as Spatial
onready var playerBody := get_node(playerBodyPath) as KinematicBody


puppet func network_update(networkPosition: Vector3, networkRotation: Vector3, networkCrouching: bool):
	playerController.translation = networkPosition
	playerController.rotation = networkRotation
	self.is_crouching = networkCrouching


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
	show_avatar = false
	playerShape.get_standing_shape().hide()
	playerShape.get_crouching_shape().hide()


func get_current_shape() -> Spatial:
	if is_crouching:
		return playerShape.get_crouching_shape()
	else:
		return playerShape.get_standing_shape()
