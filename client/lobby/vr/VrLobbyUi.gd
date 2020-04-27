extends "res://client/lobby/ClientLobby.gd"


func on_start_game():
	vr.log_info("on_start_game")
	vr.switch_scene("res://client/game/mode/fugitive/VrClientFugitiveGame.tscn")


func on_disconnect():
	vr.log_info("on_disconnect")
	vr.switch_scene("res://client/main_menu/vr/VrClientMainMenu.tscn")
