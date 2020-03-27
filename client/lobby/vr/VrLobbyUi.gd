extends "res://client/lobby/ClientLobby.gd"

func on_start_game():
	vr.log_info("on_start_game")
	get_tree().change_scene("res://client/game/vr/VrClientGame.tscn")
