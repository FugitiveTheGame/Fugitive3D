extends ClientFugitiveGame


func create_player_seeker_node() -> Node:
	var scene = preload("res://client/game/mode/fugitive/seeker/vr/VrSeekerController.tscn")
	return scene.instance()


func create_player_hider_node() -> Node:
	var scene = preload("res://client/game/mode/fugitive/hider/vr/VrHiderController.tscn")
	return scene.instance()
