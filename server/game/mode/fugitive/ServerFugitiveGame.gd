extends FugitiveGame


var configuredPlayers := {}
var readyPlayers := {}

func unconfigured_players() -> int:
	var count := 0
	for playerId in GameData.players:
		if not configuredPlayers.has(playerId):
			count += 1
	
	return count


func not_ready_players() -> int:
	var count := 0
	for playerId in GameData.players:
		if not readyPlayers.has(playerId):
			count += 1
	
	return count


func server_remove_player(playerId: int):
	# If all players are gone, return to lobby
	if GameData.players.empty():
		print("All players disconnected, returning to lobby")
		get_tree().change_scene("res://server/lobby/ServerLobby.tscn")
	else:
		print("Players remaining: %d" % GameData.players.size())
		
		if stateMachine.current_state.name == FugitiveStateMachine.STATE_CONFIGURING:
			check_all_configured()
		elif stateMachine.current_state.name == FugitiveStateMachine.STATE_NOT_READY:
			check_all_ready()


func _ready():
	ClientNetwork.connect("remove_player", self, "server_remove_player")


func load_map():
	.load_map()
	map.get_countdown_timer().connect("timeout", self, "countdown_timer_timeout")
	map.get_headstart_timer().connect("timeout", self, "headstart_timer_timeout")


remote func on_client_configured(playerId: int):
	print("client configured: %s" % playerId)
	configuredPlayers[playerId] = true
	
	check_all_configured()

func check_all_configured():
	# All clients are done, unpause the game
	if unconfigured_players() == 0:
		print("Waiting for players to ready up...")
		rpc("on_all_clients_configured")
	else:
		print("Still waiting on %d players" % unconfigured_players())


remote func on_client_ready(playerId: int):
	print("client ready: %s" % playerId)
	readyPlayers[playerId] = true
	
	check_all_ready()


func check_all_ready():
	if not_ready_players() > 0:
		print("Still waiting on %d players" % not_ready_players())
	# All clients are done, unpause the game
	else:
		stateMachine.transition_by_name(FugitiveStateMachine.TRANS_READY)
		print("Starting the countdown")
		rpc("on_all_ready")


# Only the Server listens to the timer
func countdown_timer_timeout():
	print("Start timer expired")
	rpc("begin_game")


func headstart_timer_timeout():
	print("Headstart timer expired")
	rpc("release_cops")


remotesync func on_go_to_lobby():
	print("SERVER: on_go_to_lobby()")
	get_tree().change_scene("res://server/lobby/ServerLobby.tscn")


func _on_FpsTimer_timeout():
	print("%d fps" % Engine.get_frames_per_second())
