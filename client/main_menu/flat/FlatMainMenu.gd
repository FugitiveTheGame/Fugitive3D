extends "res://client/main_menu/MainMenu.gd"

@export var settingsWindowPath: NodePath
@onready var settingsWindow := get_node(settingsWindowPath) as Window

@export var debugButtonPath: NodePath
@onready var debugButton := get_node(debugButtonPath) as Button

@export var exploreDialogPath: NodePath
@onready var exploreDialog := get_node(exploreDialogPath) as ConfirmationDialog


func _ready():
	super._ready()
	debugButton.visible = OS.is_debug_build()


func go_to_lobby():
	get_tree().change_scene_to_file("res://client/lobby/flat/FlatLobby.tscn")


func _on_SettingsButton_pressed():
	settingsWindow.popup_centered()


func _on_DebugButton_pressed():
	get_tree().change_scene_to_file("res://client/game/mode/fugitive/FugitiveGame-dev.tscn")


# Allow back to exit on mobile
func _notification(what):
	if is_inside_tree():
		if what == NOTIFICATION_WM_GO_BACK_REQUEST: 
			print("Closing game")
			get_tree().quit()


func _on_ExploreButton_pressed():
	exploreDialog.popup_centered()


func _on_ExploreDialog_confirmed():
	get_tree().change_scene_to_file("res://client/explore/FlatExploreGame.tscn")
