extends ClientFugitiveGame


func on_disconnect():
	get_tree().change_scene("res://client/main_menu/vr/VrClientMainMenu.tscn")


func create_player_seeker_node() -> Node:
	var scene = preload("res://client/game/mode/fugitive/seeker/vr/VrSeekerController.tscn")
	return scene.instance()


func create_player_hider_node() -> Node:
	var scene = preload("res://client/game/mode/fugitive/hider/vr/VrHiderController.tscn")
	return scene.instance()
