extends "res://client/lobby/ClientLobby.gd"


func on_start_game():
	vr.log_info("on_start_game")
	var mapId = GameData.general[GameData.GENERAL_MAP]
	vr.switch_scene(Maps.get_game_scene(mapId, Maps.TYPE_VR))


func on_disconnect():
	vr.log_info("on_disconnect")
	vr.switch_scene("res://client/main_menu/vr/VrClientMainMenu.tscn")
