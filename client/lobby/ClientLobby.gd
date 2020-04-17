extends Lobby

func _ready():
	ClientNetwork.connect("start_game", self, "on_start_game")
	ClientNetwork.connect("lost_connection_to_server", self, "on_disconnect")
	
	# Tell the server about you
	ServerNetwork.register_self(get_tree().get_network_unique_id(), ClientNetwork.localPlayerName)


func _on_StartButton_pressed():
	ClientNetwork.start_game()


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
