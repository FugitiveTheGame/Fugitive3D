extends "res://client/main_menu/MainMenu.gd"

export(NodePath) var settingsDialogPath: NodePath
onready var settingsDialog := get_node(settingsDialogPath) as WindowDialog

export(NodePath) var driverLabelPath: NodePath
onready var driverLabel := get_node(driverLabelPath) as Label

export(NodePath) var debugButtonPath: NodePath
onready var debugButton := get_node(debugButtonPath) as Button


func _ready():
	if OS.is_debug_build():
		debugButton.visible = true
		driverLabel.text = ProjectSettings.get_setting("rendering/quality/driver/driver_name")
		driverLabel.visible = true


func go_to_lobby():
	vr.switch_scene("res://client/lobby/vr/VrLobby.tscn")


func _on_DebugButton_pressed():
	vr.switch_scene("res://client/game/mode/fugitive/FugitiveGame-dev-vr.tscn")


func _on_SettingsButton_pressed():
	settingsDialog.popup_centered()
