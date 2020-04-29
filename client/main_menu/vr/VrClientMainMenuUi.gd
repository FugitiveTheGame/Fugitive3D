extends "res://client/main_menu/MainMenu.gd"

export(NodePath) var settingsDialogPath: NodePath
onready var settingsDialog := get_node(settingsDialogPath) as WindowDialog

func _ready():
	$DebugButton.visible = OS.is_debug_build()


func go_to_lobby():
	vr.switch_scene("res://client/lobby/vr/VrLobby.tscn")


func _on_DebugButton_pressed():
	vr.switch_scene("res://client/game/mode/fugitive/FugitiveGame-dev-vr.tscn")


func _on_SettingsButton_pressed():
	settingsDialog.popup_centered()
