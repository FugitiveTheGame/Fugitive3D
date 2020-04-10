extends "res://client/game/player/controller/vr/VrPlayerController.gd"


func _input(event):
	#if event.is_action_released("flat_player_jump"):
	#	pass
	pass


func on_state_not_ready():
	$OQ_LeftController/HudCanvas/HudContainer/PregameHud.show()


func on_state_ready():
	$OQ_LeftController/HudCanvas/HudContainer/PregameHud.show_ready()
