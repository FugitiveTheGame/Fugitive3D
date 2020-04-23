extends FugitiveGame


var unconfiguredPlayers := {}
var unreadyPlayers := {}


func server_remove_player(playerId: int):
	# If all players are gone, return to lobby
	if GameData.players.empty():
		print("All players disconnected, returning to lobby")
		get_tree().change_scene("res://server/lobby/ServerLobby.tscn")
	else:
		print("Players remaining: %d" % GameData.players.size())


func _ready():
	ClientNetwork.connect("remove_player", self, "server_remove_player")
	
	for playerId in GameData.players:
		unconfiguredPlayers[playerId] = playerId


func load_map(mapPath: String):
	.load_map(mapPath)
	map.get_start_timer().connect("timeout", self, "start_timer_timeout")
	map.get_headstart_timer().connect("timeout", self, "headstart_timer_timeout")


remote func on_client_configured(playerId: int):
	print("client configured: %s" % playerId)
	unconfiguredPlayers.erase(playerId)
	unreadyPlayers[playerId] = playerId
	print("Still waiting on %d players" % unconfiguredPlayers.size())
	
	# All clients are done, unpause the game
	if unconfiguredPlayers.empty():
		print("Waiting for players to ready up...")
		rpc("on_all_clients_configured")


remote func on_client_ready(playerId: int):
	print("client ready: %s" % playerId)
	if unreadyPlayers.erase(playerId):
		print("Still waiting on %d players" % unreadyPlayers.size())
		
		# All clients are done, unpause the game
		if unreadyPlayers.empty():
			stateMachine.transition_by_name(FugitiveStateMachine.TRANS_READY)
			print("Starting the countdown")
			rpc("on_all_ready")


# Only the Server listens to the timer
func start_timer_timeout():
	print("Start timer expired")
	rpc("begin_game")


func headstart_timer_timeout():
	print("Headstart timer expired")
	rpc("release_cops")


remotesync func on_go_to_lobby():
	print("SERVER: on_go_to_lobby()")
	get_tree().change_scene("res://server/lobby/ServerLobby.tscn")
