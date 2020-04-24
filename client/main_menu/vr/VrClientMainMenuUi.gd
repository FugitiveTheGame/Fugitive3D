extends "res://client/main_menu/MainMenu.gd"

func go_to_lobby():
	get_tree().change_scene("res://client/lobby/vr/VrLobby.tscn")


func _on_DebugButton_pressed():
	get_tree().change_scene("res://client/game/mode/fugitive/FugitiveGame-dev-vr.tscn")
