extends "res://client/main_menu/MainMenu.gd"

export(NodePath) var settingsWindowPath: NodePath
onready var settingsWindow := get_node(settingsWindowPath) as WindowDialog

export(NodePath) var debugButtonPath: NodePath
onready var debugButton := get_node(debugButtonPath) as Button

export(NodePath) var exploreDialogPath: NodePath
onready var exploreDialog := get_node(exploreDialogPath) as ConfirmationDialog


func _ready():
	debugButton.visible = OS.is_debug_build()


func go_to_lobby():
	get_tree().change_scene("res://client/lobby/flat/FlatLobby.tscn")


func _on_SettingsButton_pressed():
	settingsWindow.popup_centered()


func _on_DebugButton_pressed():
	get_tree().change_scene("res://client/game/mode/fugitive/FugitiveGame-dev.tscn")


# Allow back to exit on mobile
func _notification(what):
	if is_inside_tree():
		if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST: 
			print("Closing game")
			get_tree().quit()


func _on_ExploreButton_pressed():
	exploreDialog.popup_centered()


func _on_ExploreDialog_confirmed():
	get_tree().change_scene("res://client/explore/FlatExploreGame.tscn")
