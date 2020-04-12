extends "res://client/game/player/controller/flat/FlatPlayerController.gd"

onready var hud := $HudCanvas/HudContainer/PregameHud

func _input(event):
	if not player.gameStarted and event.is_action_released("flat_player_jump"):
		player.set_ready()


func _process(delta):
	allowMovement = not player.frozen


func on_state_not_ready():
	$HudCanvas/HudContainer/PregameHud.show()


func on_state_ready():
	$HudCanvas/HudContainer/PregameHud.show_ready()


func on_state_countdown():
	$HudCanvas/HudContainer/PregameHud.show_start_timer()


func on_state_headstart():
	$HudCanvas/HudContainer/PregameHud.show_headstart_timer()


func on_state_playing():
	$HudCanvas/HudContainer/PregameHud.hide()
