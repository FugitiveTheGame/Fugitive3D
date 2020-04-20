extends "res://client/game/player/controller/flat/FlatPlayerController.gd"

onready var hud := $HudCanvas/HudContainer/PregameHud

func _input(event):
	if not player.gameStarted and event.is_action_released("flat_player_jump"):
		player.set_ready()
	
	if event.is_action_released("flat_player_use"):
		var player := get_player()
		if player.car == null:
			var cars := get_tree().get_nodes_in_group(Groups.CARS)
			for car in cars:
				if car.enterArea.overlaps_body(player.playerBody):
					# If we entered the car, then stop searching
					if car.enter_car(player):
						update_camera_to_head()
						break
		else:
			player.car.exit_car(player)
			update_camera_to_head()


func _process(delta):
	allowMovement = not player.frozen and player.car == null


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
