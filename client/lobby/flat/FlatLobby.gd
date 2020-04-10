extends "res://client/lobby/ClientLobby.gd"

func on_start_game():
	get_tree().change_scene("res://client/game/mode/fugitive/FlatClientFugitiveGame.tscn")
