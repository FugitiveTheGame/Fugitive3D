extends ClientFugitiveGame

func _ready():
	vr.scene_switch_root = self


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
