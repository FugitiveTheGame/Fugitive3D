extends "res://client/game/ClientGame.gd"


func create_player_seeker_node() -> Node:
	var scene = preload("res://client/game/player/seeker/flat/FlatClientSeeker.tscn")
	return scene.instance()


func create_player_hider_node() -> Node:
	var scene = preload("res://client/game/player/hider/flat/FlatClientHider.tscn")
	return scene.instance()
