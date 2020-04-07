tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("PlayerSpawn", "Spatial", preload("res://common/game/mode/HiderSpawn.gd"), preload("res://common/game/mode/player_spawn_icon.png"))


func _exit_tree():
	remove_custom_type("PlayerSpawn")
