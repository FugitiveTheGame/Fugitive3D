extends "res://addons/OQ_Toolkit/OQ_ARVROrigin/scripts/Feature_PlayerCollision.gd"

export(NodePath) var playerPath: NodePath
onready var player := get_node(playerPath) as Player

func get_player():
	return player
