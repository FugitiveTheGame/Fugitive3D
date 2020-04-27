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
					car.request_enter_car(player)
					break
		else:
			player.car.request_exit_car(player)
	
	if event.is_action_released("flat_car_horn"):
		if player.car != null and player.car.is_driver(player.id):
			player.car.honk_horn()


func _process(delta):
	allowMovement = not player.frozen and player.car == null
	
	# Only allow the driver to control the car
	if player.car != null and player.car.is_driver(player.id):
		var forward := Input.is_action_pressed("flat_player_up")
		var backward := Input.is_action_pressed("flat_player_down")
		var left := Input.is_action_pressed("flat_player_left")
		var right := Input.is_action_pressed("flat_player_right")
		var breaking := Input.is_action_pressed("flat_player_jump")
		
		player.car.process_input(forward, backward, left, right, breaking, delta)


func on_car_entered(car):
	update_camera_to_head()


func on_car_exited(car):
	update_camera_to_head()


func on_state_not_ready():
	$HudCanvas/HudContainer/PregameHud.show()


func on_state_ready():
	$HudCanvas/HudContainer/PregameHud.show_ready()


func on_state_countdown():
	$HudCanvas/HudContainer/PregameHud.show_start_timer()


func on_state_headstart():
	$HudCanvas/HudContainer/PregameHud.show_headstart_timer()


func on_state_playing():
	$HudCanvas/HudContainer/PregameHud.start_play_phase()


func on_state_game_over():
	$HudCanvas/HudContainer/EndGameHud.team_won( GameData.currentGame.winningTeam )
