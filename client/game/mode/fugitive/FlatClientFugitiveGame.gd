extends ClientFugitiveGame


func _exit_tree():
	# Release the mouse if we're leaving the scene
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


remotesync func on_go_to_lobby():
	print("CLIENT: on_go_to_lobby()")
	get_tree().change_scene("res://client/lobby/flat/FlatLobby.tscn")


func on_disconnect():
	get_tree().change_scene("res://client/main_menu/flat/FlatMainMenu.tscn")


func create_player_seeker_node() -> Node:
	var scene = load("res://client/game/mode/fugitive/seeker/flat/FlatSeekerController.tscn")
	return scene.instance()


func create_player_hider_node() -> Node:
	var scene = load("res://client/game/mode/fugitive/hider/flat/FlatHiderController.tscn")
	return scene.instance()


func goto_main_menu():
	get_tree().change_scene("res://client/main_menu/flat/FlatMainMenu.tscn")
