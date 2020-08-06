extends "res://client/main_menu/MainMenu.gd"

export(NodePath) var settingsDialogPath: NodePath
onready var settingsDialog := get_node(settingsDialogPath) as WindowDialog

export(NodePath) var vrModeLabelPath: NodePath
onready var vrModeLabel := get_node(vrModeLabelPath) as Label

export(NodePath) var driverLabelPath: NodePath
onready var driverLabel := get_node(driverLabelPath) as Label

export(NodePath) var debugButtonPath: NodePath
onready var debugButton := get_node(debugButtonPath) as Button

export(NodePath) var exploreDialogPath: NodePath
onready var exploreDialog := get_node(exploreDialogPath) as ConfirmationDialog


func _enter_tree():
	UserData.connect("user_data_updated", self, "on_user_data_updated")


func _ready():
	if OS.is_debug_build():
		debugButton.visible = true
		driverLabel.text = ProjectSettings.get_setting("rendering/quality/driver/driver_name")
		driverLabel.visible = true
	else:
		debugButton.visible = false
		driverLabel.visible = false
	
	update_vr_mode_label()


func _exit_tree():
	UserData.disconnect("user_data_updated", self, "on_user_data_updated")


func go_to_lobby():
	vr.switch_scene("res://client/lobby/vr/VrLobby.tscn")


func _on_DebugButton_pressed():
	vr.switch_scene("res://client/game/mode/fugitive/FugitiveGame-dev-vr.tscn")


func _on_SettingsButton_pressed():
	settingsDialog.popup_centered()


func on_user_data_updated():
	call_deferred("update_vr_mode_label")


func update_vr_mode_label():
	var modeName: String
	if UserData.data.vr_standing:
		modeName = "Standing"
	else:
		modeName = "Seated"
	
	if vrModeLabel != null:
		vrModeLabel.text = "VR Mode: %s" % modeName


func _on_ExploreButton_pressed():
	exploreDialog.popup_centered()


func _on_ExploreDialog_confirmed():
	get_tree().change_scene("res://client/explore/VrExploreGame.tscn")
