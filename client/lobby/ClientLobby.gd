extends Lobby

export(NodePath) var startButtonPath: NodePath
onready var startButton := get_node(startButtonPath) as Button

export(NodePath) var leaveButtonPath: NodePath
onready var leaveButton := get_node(leaveButtonPath) as Button


var is_host := false

func _ready():
	ClientNetwork.connect("start_game", self, "on_start_game")
	ClientNetwork.connect("lost_connection_to_server", self, "on_disconnect")
	
	# Tell the server about you
	ServerNetwork.register_self(get_tree().get_network_unique_id(), ClientNetwork.localPlayerName)


func _on_StartButton_pressed():
	rpc("start_timer")


func _on_LeaveButton_pressed():
	# Disconnect from the server
	ClientNetwork.reset_network()
	on_disconnect()


func on_start_game():
	print("on_start_game() MUST BE IMPLEMENTED")
	assert(false)


func on_disconnect():
	print("on_disconnect() MUST BE IMPLEMENTED")
	assert(false)


func create_player(playerId: int):
	.create_player(playerId)
	update_host(playerId)


func update_player(playerId: int):
	.update_player(playerId)
	update_host(playerId)


func update_host(playerId: int):
	if playerId == get_tree().get_network_unique_id():
		var player = GameData.players[playerId]
		is_host = player[GameData.PLAYER_HOST]
	
	if is_host:
		startButton.show()
	else:
		startButton.hide()


func update_ui():
	.update_ui()
	if startButton != null:
		startButton.disabled = not can_start() or is_starting


func _process(delta):
	if is_starting:
		$StartLabel.text = TimeUtils.format_seconds_for_display($StartTimer.time_left)


remotesync func start_timer():
	.start_timer()
	$StartLabel.show()
	$StartTimer.start()


func _on_StartTimer_timeout():
	# The host will tell all other clients to start the game
	if is_host:
		ClientNetwork.start_game()
