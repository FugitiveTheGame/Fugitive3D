extends Lobby

export(NodePath) var startButtonPath: NodePath
onready var startButton := get_node(startButtonPath) as Button

export(NodePath) var leaveButtonPath: NodePath
onready var leaveButton := get_node(leaveButtonPath) as Button

export(NodePath) var randomButtonPath: NodePath
onready var randomButton := get_node(randomButtonPath) as Button

export(NodePath) var randomCooldownTimerPath: NodePath
onready var randomCooldownTimer := get_node(randomCooldownTimerPath) as Timer

export (NodePath) var helpDialogPath: NodePath
onready var helpDialog := get_node(helpDialogPath) as WindowDialog

export (NodePath) var voiceChatContainerPath: NodePath
onready var voiceChatContainer := get_node(voiceChatContainerPath) as Node


func _enter_tree():
	ClientNetwork.connect("lost_connection_to_server", self, "on_disconnect")


func _exit_tree():
	ClientNetwork.disconnect("lost_connection_to_server", self, "on_disconnect")


func _ready():
	var clientType := PlatformTypeUtils.get_platform_type()
	
	# Tell the server about you
	ServerNetwork.register_self(get_tree().get_network_unique_id(), clientType, ClientNetwork.localPlayerName, UserData.GAME_VERSION)
	
	$StartLabel.hide()
	
	leaveButton.grab_focus()


func _on_StartButton_pressed():
	GameAnalytics.design_event("lobby_start_game_pressed")
	ClientNetwork.start_lobby_countdown()


func _on_LeaveButton_pressed():
	leave_lobby()


func leave_lobby():
	print("Leaving lobby")
	GameAnalytics.design_event("lobby_manual_leave")
	# Disconnect from the server
	ClientNetwork.reset_network()
	on_disconnect()


func on_disconnect():
	print("on_disconnect() MUST BE IMPLEMENTED")
	assert(false)


func update_ui():
	.update_ui()
	
	randomButton.disabled = not is_host or is_starting or (not randomCooldownTimer.is_stopped())
	startButton.visible = is_host
	
	if startButton != null:
		startButton.disabled = not can_start() or is_starting


func _process(delta):
	if is_starting:
		var time := TimeUtils.format_seconds_for_display($StartTimer.time_left)
		$StartLabel.text = "Game Starting: %s" % time


func on_start_lobby_countdown():
	.on_start_lobby_countdown()
	
	randomButton.disabled = true
	randomCooldownTimer.stop()
	
	$StartLabel.show()
	$StartTimer.start()
	$CountDownAudio.play()


func _on_StartTimer_timeout():
	# The host will tell all other clients to start the game
	if is_host:
		ClientNetwork.start_game()


func _on_RandomButton_pressed():
	randomButton.disabled = true
	randomCooldownTimer.start()
	GameAnalytics.design_event("lobby_randomize_teams")
	ServerNetwork.randomize_teams()


# Allow back to leave the lobby on mobile
func _notification(what):
	if is_inside_tree():
		if what == MainLoop.NOTIFICATION_WM_GO_BACK_REQUEST: 
			leave_lobby()


func _on_HelpButton_pressed():
	GameAnalytics.design_event("lobby_help_shown")
	var mapId = GameData.general[GameData.GENERAL_MAP]
	var mode := Maps.get_mode_for_map(mapId)
	helpDialog.showGameMode = mode[Maps.MODE_NAME]
	helpDialog.popup_centered()


func create_player_ui(playerId: int):
	# First add the VOIP node for this player
	var playerVoipNode = null
	if playerId == get_tree().get_network_unique_id():
		playerVoipNode = preload("res://common/lobby/voip/LobbyLocalVoiceChat.tscn").instance()
	else:
		playerVoipNode = preload("res://common/lobby/voip/LobbyRemoteVoiceChat.tscn").instance()
	
	playerVoipNode.set_network_master(playerId)
	playerVoipNode.set_name(str(playerId))
	voiceChatContainer.add_child(playerVoipNode)
	
	# Then create the player list item
	.create_player_ui(playerId)
	
	# Finally hook up the list item to the voip node
	var playerListItem := find_player_node(playerId)
	playerListItem.voice_chat = playerVoipNode.get_node("VoiceChat")


func remove_player(playerId: int):
	.remove_player(playerId)
	
	var nodeName := str(playerId)
	for child in get_children():
		if child.name == nodeName:
			child.queue_free()
			break


func _on_RandomizeCooldownTimer_timeout():
	if is_host and not is_starting:
		randomButton.disabled = false
