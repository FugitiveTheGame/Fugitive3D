extends "res://client/game/player/controller/flat/FlatPlayerController.gd"


func _input(event):
	if event.is_action_released("flat_player_jump"):
		pass


func on_state_not_ready():
	$HudCanvas/HudContainer/PregameHud.show()


func on_state_ready():
	$HudCanvas/HudContainer/PregameHud.show_ready()
