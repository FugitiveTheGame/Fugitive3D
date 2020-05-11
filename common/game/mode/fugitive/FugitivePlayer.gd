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
	else:
		self.is_crouching = false


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
	newEntry.isCrouching = is_crouching
	newEntry.playerType = playerType
	newEntry.frozen = frozen
	newEntry.entryType = "PLAYER"
	return newEntry

func update_player_name_state():
	# Always team mate names
	var show: bool
	# Always show for frozen players
	if frozen:
		show = true
	# Always show for team mates
	if localPlayerType == playerType:
		show = true
	# Player is on other team, and is Hider
	elif playerType == FugitiveTeamResolver.PlayerType.Hider:
		# Any Hider in a winzone has their name shown
		if is_in_winzone():
			show = true
		else:
			show = false
	# Player is on other team, and is Hider
	elif playerType == FugitiveTeamResolver.PlayerType.Seeker:
		# If local player is a Hider, and in a winzone, see all names
		if GameData.get_current_player().is_in_winzone():
			show = true
		else:
			show = false
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


func _on_AutoReadyTimer_timeout():
	print("Forcing player ready")
	set_ready()


func is_in_winzone() -> bool:
	for zone in win_zones:
		if zone.overlaps_body(playerBody):
			return true
	return false
