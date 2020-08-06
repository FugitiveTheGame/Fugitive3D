extends "res://client/explore/ExploreGame.gd"


remotesync func on_go_to_lobby():
	# This is normally handled by other mechanisms in the real game
	# we must manually do it here
	ClientNetwork.reset_network()
	vr.switch_scene("res://client/main_menu/vr/VrClientMainMenu.tscn")


func on_disconnect():
	vr.switch_scene("res://client/main_menu/vr/VrClientMainMenu.tscn")


func create_player_seeker_node() -> Node:
	var scene = preload("res://client/game/mode/fugitive/seeker/vr/VrSeekerController.tscn")
	return scene.instance()


func create_player_hider_node() -> Node:
	var scene = preload("res://client/game/mode/fugitive/hider/vr/VrHiderController.tscn")
	return scene.instance()


func goto_main_menu():
	vr.switch_scene("res://client/main_menu/vr/VrClientMainMenu.tscn")
