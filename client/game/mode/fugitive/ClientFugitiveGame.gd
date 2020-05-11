extends FugitiveGame
class_name ClientFugitiveGame


func _enter_tree():
	ClientNetwork.connect("lost_connection_to_server", self, "on_disconnect")


func _exit_tree():
	ClientNetwork.disconnect("lost_connection_to_server", self, "on_disconnect")


func on_disconnect():
	print("ClientFugitiveGame: on_disconnect: MUST BE OVERRIDEN")
	assert(false)


func pre_configure():
	.pre_configure()
	
	# Get a handle to the local player
	localPlayer = get_tree().get_nodes_in_group(Groups.LOCAL_PLAYER)[0] as Player
	# Game listens to player in order to change state
	localPlayer.connect("local_player_ready", self, "local_player_ready")
	localPlayer.playerController.connect("return_to_main_menu", self, "on_return_to_main_menu")
	
	
	if not get_tree().is_network_server():
		print("Sending client configured")
		rpc_id(ServerNetwork.SERVER_ID, "on_client_configured", get_tree().get_network_unique_id())
	# This is a special case to help development testing
	else:
		print("DEV: forcing on_all_clients_configured")
		on_all_clients_configured()
	
	GameAnalytics.design_event("start_game")


func local_player_ready():
	if stateMachine.is_current_state(FugitiveStateMachine.STATE_NOT_READY):
		print("Reporting ready: %d" % get_tree().get_network_unique_id())
		stateMachine.transition_by_name(FugitiveStateMachine.TRANS_READY)
		
		# Report that this client is done
		rpc_id(ServerNetwork.SERVER_ID, "on_client_ready", get_tree().get_network_unique_id())


func on_state_countdown(current_state: State, transition: Transition):
	.on_state_countdown(current_state, transition)
	$PregameCountdownAudio.play()


func on_state_playing_headstart(current_state: State, transition: Transition):
	print("Playing start sound")
	$StartAudio.play()


# User request to leave the game
func on_return_to_main_menu():
	ClientNetwork.reset_network()
	GameAnalytics.design_event("quit_mid_game")
	call_deferred("goto_main_menu")


func goto_main_menu():
	print("goto_main_menu() MUST BE OVERIDDEN")
	assert(false)


func finish_game(playerType: int):
	.finish_game(playerType)
	GameAnalytics.design_event("game_complete")
