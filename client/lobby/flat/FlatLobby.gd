extends "res://client/lobby/ClientLobby.gd"

func on_start_game():
	var mapId = GameData.general[GameData.GENERAL_MAP]
	get_tree().change_scene(Maps.get_game_scene(mapId, Maps.TYPE_FLAT))


func on_disconnect():
	get_tree().change_scene("res://client/main_menu/flat/FlatMainMenu.tscn")
