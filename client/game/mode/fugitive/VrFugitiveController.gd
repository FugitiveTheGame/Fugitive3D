extends "res://client/game/player/controller/vr/VrPlayerController.gd"

onready var pregameHud := hud.find_node("PregameHud", true, false) as Control
onready var endgameHud := hud.find_node("EndGameHud", true, false) as Control
onready var playerHeightHud := hud.find_node("HeightContainer", true, false) as Control
onready var overviewMapHud := hud.find_node("OverviewMapHud", true, false) as Control

const dead_zone := 0.125


# Allow child classes to override this functionality
func show_map(show: bool):
	overviewMapHud.visible = show


func _ready():
	uiRaycast.connect("visibility_changed", self, "on_ui_raycast_visibility_changed")


func _physics_process(delta):
	#######################
	# Process per-frame input
	
	if not player.gameStarted and (vr.button_just_released(vr.BUTTON.LEFT_INDEX_TRIGGER) or vr.button_just_released(vr.BUTTON.RIGHT_INDEX_TRIGGER)):
		player.set_ready()
	 
	show_map( vr.button_pressed(vr.BUTTON.LEFT_THUMBSTICK) )

	if debounced_button_just_released(vr.BUTTON.A):
		if player.car == null:
			var cars := get_tree().get_nodes_in_group(Groups.CARS)
			for car in cars:
				if car.enterArea.overlaps_body(player.playerBody):
					car.request_enter_car(player)
					break
		else:
			player.car.request_exit_car(player)
	
	if debounced_button_just_released(vr.BUTTON.LEFT_INDEX_TRIGGER):
		if player.car != null and player.car.is_driver(player.id):
			player.car.honk_horn()


func _process(delta):
	#######################
	# Car movement input
	
	locomotion.allowMovement = not player.frozen and player.car == null
	
	if player.car != null and player.car.is_driver(player.id):
		var x = -vr.get_controller_axis(vr.AXIS.LEFT_JOYSTICK_X);
		var y = vr.get_controller_axis(vr.AXIS.LEFT_JOYSTICK_Y);
		# Car dead zone
		if abs(x) < 0.5:
			x = 0.0
		
		var forward := false
		var backward := false
		
		if y > dead_zone:
			forward = true
		elif y < -dead_zone:
			backward = true
		
		var left := false
		var right := false
		
		if x > dead_zone:
			left = true
		elif x < -dead_zone:
			right = true
		
		var breaking := vr.button_pressed(vr.BUTTON.RIGHT_INDEX_TRIGGER) as bool
		
		player.car.process_input(forward, backward, left, right, breaking, delta)


func on_car_entered(car):
	locomotion.allowTurn = false
	vr.vrOrigin.is_fixed = true


func on_car_exited(car):
	vr.vrOrigin.is_fixed = false
	transform.origin.y = standingHeight
	locomotion.allowTurn = true


func car_update(position: Vector3):
	global_transform.origin = position
	transform.origin.y -= (standingHeight * 0.45)


func on_state_not_ready():
	pregameHud.show()


func on_state_ready():
	# Do this automatically id the user hasn't done it manually yet
	if standingHeight <= 0.0:
		set_standing_height()
	
	pregameHud.show_ready()


func on_state_countdown():
	pregameHud.show_start_timer()


func on_state_headstart():
	playerHeightHud.hide()
	pregameHud.show_headstart_timer()


func on_state_playing():
	pregameHud.start_play_phase()


func on_state_game_over():
	endgameHud.team_won( GameData.currentGame.winningTeam )
	# Show the ui raycast for interacting with the end-game menu
	uiRaycast.show()


func on_ui_raycast_visibility_changed():
	# In the end-game state, we always want the raycast shown
	if not uiRaycast.visible and player.gameEnded:
		uiRaycast.show()
