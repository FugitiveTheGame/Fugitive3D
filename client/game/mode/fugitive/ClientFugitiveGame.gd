extends FugitiveGame
class_name ClientFugitiveGame


remotesync func on_go_to_lobby():
	print("CLIENT: on_go_to_lobby()")
	
	if OS.has_feature("client_flat"):
		go_to_flat_lobby()
	elif OS.has_feature("client_vr_desktop"):
		go_to_pc_vr_lobby()
	elif OS.has_feature("client_vr_mobile"):
		go_to_mobile_vr_lobby()
	else:
		go_to_flat_lobby()


func go_to_flat_lobby():
	get_tree().change_scene("res://client/lobby/flat/FlatLobby.tscn")


func go_to_pc_vr_lobby():
	get_tree().change_scene("res://client/lobby/vr/VrLobby.tscn")


func go_to_mobile_vr_lobby():
	get_tree().change_scene("res://client/lobby/vr/VrLobby.tscn")


func pre_configure():
	.pre_configure()
	
	# Get a handle to the local player
	localPlayer = get_tree().get_nodes_in_group(Groups.LOCAL_PLAYER)[0] as Player
	# Game listens to player in order to change state
	localPlayer.connect("local_player_ready", self, "local_player_ready")
	
	print("Sending client configured")
	if not get_tree().is_network_server():
		rpc_id(ServerNetwork.SERVER_ID, "on_client_configured", get_tree().get_network_unique_id())
	# This is a special case to help development testing
	else:
		on_all_clients_configured()


func local_player_ready():
	if stateMachine.is_current_state(FugitiveStateMachine.STATE_NOT_READY):
		print("Reporting ready: %d" % get_tree().get_network_unique_id())
		stateMachine.transition_by_name(FugitiveStateMachine.TRANS_READY)
		
		# Report that this client is done
		rpc_id(ServerNetwork.SERVER_ID, "on_client_ready", get_tree().get_network_unique_id())
