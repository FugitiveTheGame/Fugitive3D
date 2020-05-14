extends Lobby

export(NodePath) var startButtonPath: NodePath
onready var startButton := get_node(startButtonPath) as Button

export(NodePath) var leaveButtonPath: NodePath
onready var leaveButton := get_node(leaveButtonPath) as Button

export(NodePath) var randomButtonPath: NodePath
onready var randomButton := get_node(randomButtonPath) as Button

export (NodePath) var helpDialogPath: NodePath
onready var helpDialog := get_node(helpDialogPath) as WindowDialog


func _enter_tree():
	ClientNetwork.connect("lost_connection_to_server", self, "on_disconnect")


func _exit_tree():
	ClientNetwork.disconnect("lost_connection_to_server", self, "on_disconnect")


func _ready():
	var clientType := PlatformTypeUtils.get_platform_type()
	
	# Tell the server about you
	ServerNetwork.register_self(get_tree().get_network_unique_id(), clientType, ClientNetwork.localPlayerName, UserData.GAME_VERSION)
	
	$StartLabel.hide()


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
	
	randomButton.disabled = not is_host or is_starting
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
	
	$StartLabel.show()
	$StartTimer.start()
	$CountDownAudio.play()


func _on_StartTimer_timeout():
	# The host will tell all other clients to start the game
	if is_host:
		ClientNetwork.start_game()


func _on_RandomButton_pressed():
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
	helpDialog.initialGameMode = mode[Maps.MODE_NAME]
	helpDialog.popup_centered()
