extends Lobby

export(NodePath) var startButtonPath: NodePath
onready var startButton := get_node(startButtonPath) as Button

export(NodePath) var leaveButtonPath: NodePath
onready var leaveButton := get_node(leaveButtonPath) as Button

export(NodePath) var randomButtonPath: NodePath
onready var randomButton := get_node(randomButtonPath) as Button


func _ready():
	ClientNetwork.connect("lost_connection_to_server", self, "on_disconnect")
	
	# Tell the server about you
	ServerNetwork.register_self(get_tree().get_network_unique_id(), ClientNetwork.localPlayerName)
	
	$StartLabel.hide()


func _on_StartButton_pressed():
	ClientNetwork.start_lobby_countdown()


func _on_LeaveButton_pressed():
	# Disconnect from the server
	ClientNetwork.reset_network()
	on_disconnect()


func on_disconnect():
	print("on_disconnect() MUST BE IMPLEMENTED")
	assert(false)


func update_ui():
	.update_ui()
	
	randomButton.disabled = not is_host
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
	ServerNetwork.randomize_teams()
