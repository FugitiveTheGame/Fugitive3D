extends Node

const SERVER_PORT := 31000
const SERVER_ID := 1
var SERVER_REPOSITORY_URL: String
const MAX_PLAYERS := 10

# Set to true to point at a locally running instance of the ServerRepository
const debug_local := false
func _init():
	if debug_local:
		SERVER_REPOSITORY_URL = "http://127.0.0.1:8080"
	else:
		SERVER_REPOSITORY_URL = "http://repository.fugitivethegame.online"


func _player_connected(id):
	print("SERVER: Player connected: " + str(id))


func _player_disconnected(id):
	print("SERVER: Player connected: " + str(id))
	# If it was the host who left, and there are any
	# players left, pick the first one and make them host
	if not GameData.players.empty():
		# No host, make the first player the new host
		if GameData.get_host() == null:
			var newHost = GameData.players.values().front()
			make_host(newHost.get_id())


# Called by clients when they connect
func register_self(playerId: int, playerName: String, gameVersion: int):
	rpc_id(SERVER_ID, "on_register_self", playerId, playerName, gameVersion)


remote func on_register_self(playerId: int, playerName: String, gameVersion: int):
	# Enforce same game_version
	if gameVersion != UserData.GAME_VERSION:
		print("Player connected with bad game version %d. Dissconnecting them." % playerId)
		ClientNetwork.force_disconnect(playerId)
		return
	
	# Default to team 0
	var playerType := 0
	var playerData = GameData.create_new_player_raw_data(playerId, playerName, playerType)
	
	# Register this client with the server
	ClientNetwork.on_register_player(playerData)
	
	# Register the new player with all existing clients
	for curPlayerId in GameData.players:
		ClientNetwork.register_player_from_raw_data(curPlayerId, playerData)
	
	# Catch the new player up on who is already here
	for curPlayerId in GameData.players:
		if curPlayerId != playerId:
			var player = GameData.players[curPlayerId]
			ClientNetwork.register_player(playerId, player)
	
	ClientNetwork.update_game_data()
	
	# If there is no host, make this player the host
	if GameData.get_host() == null:
		make_host(playerId)


func make_host(playerId: int):
	print("Server: Making %d host" % playerId)
	var playerInfo := GameData.get_player(playerId) as PlayerData
	playerInfo.set_is_host(true)
	ClientNetwork.update_player(playerInfo)

func is_hosting() -> bool:
	if get_tree().network_peer != null and get_tree().network_peer.get_connection_status() != 0: # NetworkedMultiplayerPeer.ConnectionStatus.CONNECTION_DISCONNECTED
		return true
	else:
		return false


func host_game(port: int = SERVER_PORT) -> bool:
	# Clear out any old state
	ClientNetwork.reset_network()
	
	var peer = NetworkedMultiplayerENet.new()
	peer.compression_mode = 4
	var result = peer.create_server(port, MAX_PLAYERS)
	if result == OK:
		get_tree().set_network_peer(peer)
		
		GameData.general[GameData.GENERAL_SEED] = OS.get_unix_time()
		
		get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
		get_tree().connect("network_peer_connected", self, "_player_connected")	
		
		print("Server started.")
		return true
	else:
		print("Failed to host game: %d" % result)
		return false


func change_player_type(playerId: int, playerType: int):
	rpc("on_change_player_type", playerId, playerType)


remote func on_change_player_type(playerId: int, playerType: int):
	var player = GameData.get_player(playerId) as PlayerData
	if player != null:
		player.set_type(playerType)
		ClientNetwork.update_player(player)
	else:
		print("ERROR: on_change_player_type() player not found for ID: %d" % playerId)


func randomize_teams():
	rpc("on_randomize_teams")


remotesync func on_randomize_teams():
	if not get_tree().is_network_server():
		return
	
	var playerIds = GameData.players.keys()
	
	var mapId = GameData.general[GameData.GENERAL_MAP]
	var mode = Maps.get_mode_for_map(mapId)
	var map = Maps.directory[mapId]
	
	var teamResolver = mode[Maps.MODE_TEAM_RESOLVER]
	
	# Array containing the number of players for each team.
	var teamLayout = teamResolver.get_random_team_layout(mapId, playerIds.size())
	
	# Randomize the order of the player ids
	playerIds.shuffle()
	
	var teamId := 0
	while not teamLayout.empty() and not playerIds.empty():
		var teamCount = teamLayout.pop_front()
	
		while teamCount > 0 and not playerIds.empty():
			teamCount -= 1
			
			var playerId = playerIds.pop_front()
			change_player_type(playerId, teamId)
		
		teamId += 1
