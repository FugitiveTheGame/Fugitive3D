extends "res://common/game/player/Player.gd"
class_name FugitivePlayer

signal local_player_ready

var playerType: int
var frozen := false

var gameStarted := false
var gameEnded := false

onready var win_zones := get_tree().get_nodes_in_group(Groups.WIN_ZONE)

var car = null setget set_car
func set_car(value):
	car = value
	
	if car != null:
		self.is_crouching = true
		stop_movement_sounds()
	else:
		self.is_crouching = false


func _ready():
	# Listen to the winzone
	for zone in win_zones:
		zone.connect("body_entered", self, "on_enter_winzone")
		zone.connect("body_exited", self, "on_exit_winzone")


func configure(_playerName: String, _playerId: int, _localPlayerType: int):
	.configure(_playerName, _playerId, _localPlayerType)
	set_player_name(_playerName)
	update_player_name_state()


func set_player_name(playerName: String):
	playerShape.get_name_label().set_label_text(playerName)


func get_history_heartbeat() -> Dictionary:
	var newEntry := {}
	newEntry.position = Vector2(global_transform.origin.x, global_transform.origin.z)
	newEntry.orientation = Utils.get_map_rotation(global_transform)
	newEntry.stamina = stamina
	newEntry.isCrouching = is_crouching
	newEntry.id = id
	newEntry.frozen = frozen
	newEntry.entryType = FugitiveEnums.EntityType.Player
	return newEntry


func update_player_name_state():
	# Always team mate names
	var show: bool
	
	var localPlayer := GameData.currentGame.localPlayer
	var isLocalPlayer := (id == get_tree().get_network_unique_id()) as bool
	var localPlayerInWinzone := (localPlayer != null and localPlayer.is_in_winzone()) as bool
	var localPlayerIsHider := (localPlayerType == FugitiveTeamResolver.PlayerType.Hider) as bool
	
	# Always hide for local player
	if isLocalPlayer:
		show = false
	# Always show for frozen players
	elif frozen:
		show = true
	# Always show in pre-game and end-game
	elif not gameStarted or gameEnded:
		show = true
	# Always show for team mates
	elif localPlayerType == playerType:
		show = true
	# Local player is on other team from this player
	else:
		# Local player is hider, this player is seeker
		if localPlayerIsHider:
			# If hider is in winzone, show seeker names
			if localPlayerInWinzone:
				show = true
			else:
				show = false
		# Local player is seeker, this player is hider
		else:
			# Any Hider in a winzone has their name shown to seekers
			if is_in_winzone():
				show = true
			else:
				show = false
	
	playerShape.get_name_label().visible = show


func is_playing() -> bool:
	return gameStarted and not gameEnded


func freeze():
	rpc("on_freeze")


remotesync func on_freeze():
	print("Player frozen: %d" % get_network_master())
	frozen = true
	update_player_name_state()
	stop_movement_sounds()


func unfreeze():
	rpc("on_unfreeze")


remotesync func on_unfreeze():
	print("Player unfrozen: %d" % get_network_master())
	frozen = false
	update_player_name_state()


func set_ready():
	print("Player reporting ready")
	$AutoReadyTimer.stop()
	emit_signal("local_player_ready")


func on_game_state_changed(newState: State, via: Transition):
	#print("Player State: %s" % newState.name)
	match newState.name:
		FugitiveStateMachine.STATE_NOT_READY:
			on_state_not_ready()
			if playerController.has_method("on_state_not_ready"):
				playerController.on_state_not_ready()
		FugitiveStateMachine.STATE_READY:
			if playerController.has_method("on_state_ready"):
				playerController.on_state_ready()
		FugitiveStateMachine.STATE_COUNTDOWN:
			if playerController.has_method("on_state_countdown"):
				playerController.on_state_countdown()
		FugitiveStateMachine.STATE_PLAYING_HEADSTART:
			gameStarted = true
			on_state_playing_headstart()
			if playerController.has_method("on_state_headstart"):
				playerController.on_state_headstart()
		FugitiveStateMachine.STATE_PLAYING:
			on_state_playing()
			if playerController.has_method("on_state_playing"):
				playerController.on_state_playing()
		FugitiveStateMachine.STATE_GAME_OVER:
			gameEnded = true
			on_state_game_over()
			if playerController.has_method("on_state_game_over"):
				playerController.on_state_game_over()


func on_state_not_ready():
	freeze()
	
	# If this is the local player, start the auto-ready timer
	if id == GameData.get_current_player_id():
		$AutoReadyTimer.start()
	
	print("Local Client State: Not Ready")


func on_state_playing_headstart():
	pass


func on_state_playing():
	print("FugPlay: on_state_playing()")
	pass


func on_state_game_over():
	stop_movement_sounds()


func _on_AutoReadyTimer_timeout():
	print("Forcing player ready")
	set_ready()


func is_in_winzone() -> bool:
	for zone in win_zones:
		if zone.overlaps_body(playerBody):
			return true
	return false


func on_enter_winzone(body):
	if body is KinematicBody:
		# When anyone enters a winzone, everyone should update their name visibility
		update_player_name_state()


func on_exit_winzone(body):
	if body is KinematicBody:
		# When anyone enters a winzone, everyone should update their name visibility
		# Must defer this call so that checks about the winzone have time to update
		call_deferred("update_player_name_state")
