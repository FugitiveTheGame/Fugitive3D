extends "res://client/game/player/controller/vr/VrPlayerController.gd"


onready var pregameHud := hud.find_node("PregameHud", true, false) as Control


func _input(event):
	if not player.gameStarted and (vr.button_just_released(vr.BUTTON.LEFT_INDEX_TRIGGER) or vr.button_just_released(vr.BUTTON.RIGHT_INDEX_TRIGGER)):
		player.set_ready()


func _process(delta):
	locomotion.allowMovement = not player.frozen


func on_state_not_ready():
	pregameHud.show()


func on_state_ready():
	pregameHud.show_ready()


func on_state_countdown():
	pregameHud.show_start_timer()


func on_state_headstart():
	pregameHud.show_headstart_timer()


func on_state_playing():
	pregameHud.hide()
