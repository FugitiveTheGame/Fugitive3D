extends "res://client/game/ClientGame.gd"


func create_player_node() -> Node:
	var scene = preload("res://client/game/player/vr/pc/VrPcPlayer.tscn")
	return scene.instance()
