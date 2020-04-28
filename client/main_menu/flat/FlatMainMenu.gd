extends "res://client/main_menu/MainMenu.gd"

export(NodePath) var settingsWindowPath: NodePath
onready var settingsWindow := get_node(settingsWindowPath) as WindowDialog

func go_to_lobby():
	get_tree().change_scene("res://client/lobby/flat/FlatLobby.tscn")


func _on_SettingsButton_pressed():
	settingsWindow.popup_centered()
