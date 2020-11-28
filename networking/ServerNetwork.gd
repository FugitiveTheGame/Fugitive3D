extends Node

const SERVER_PORT := 31000
const SERVER_ID := 1
var SERVER_REPOSITORY_URL: String
const MAX_PLAYERS := 10

var is_joinable := false


# Set to true to point at a locally running instance of the ServerRepository
const debug_local := false
func _init():
	if debug_local:
		SERVER_REPOSITORY_URL = "http://127.0.0.1:8080"
	else:
		SERVER_REPOSITORY_URL = "http://repository.fugitivethegame.online"


func _exit_tree():
	if get_tree().is_connected("network_peer_disconnected", self, "_player_disconnected"):
		get_tree().disconnect("network_peer_disconnected", self, "_player_disconnected")
	
	if get_tree().is_connected("network_peer_connected", self, "_player_connected"):
		get_tree().disconnect("network_peer_connected", self, "_player_connected")	


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
			if newHost != null:
				make_host(newHost.get_id())


func change_map(map_id: String):
	rpc_id(SERVER_ID, "on_change_map", map_id)


remote func on_change_map(map_id: String):
	if GameData.currentGame == null:
		GameData.general[GameData.GENERAL_MAP] = map_id
		
		ClientNetwork.update_game_data()
	else:
		print("WARN: Not allowed to change map during game")


# Called by clients when they connect
func register_self(playerId: int, platformType: int, playerName: String, gameVersion: int):
	rpc_id(SERVER_ID, "on_register_self", playerId, platformType, playerName, gameVersion)


remote func on_register_self(playerId: int, platformType: int, playerName: String, gameVersion: int):
	# Enforce same game_version
	if gameVersion != UserData.GAME_VERSION:
		print("Player connected with bad game version %d. Dissconnecting them." % playerId)
		ClientNetwork.force_disconnect(playerId, "Bad game version %d Server was %d" % [gameVersion, UserData.GAME_VERSION])
		return
	
	if not is_joinable:
		print("Player connection Refused, not currently joinable.")
		ClientNetwork.force_disconnect(playerId, "Server is not currently joinable. Please try again shortly.")
		return
	
	var existingPlayer = GameData.get_player(playerId)
	# Ready up an existing plauyer
	if existingPlayer != null:
		existingPlayer.set_lobby_ready(true)
		ClientNetwork.update_players()
	# Register a totally new player
	else:
		# Default to team 0
		var playerType := 0
		var playerData = GameData.create_new_player_raw_data(playerId, platformType, playerName, playerType)
		
		# Register this client with the server
		ClientNetwork.on_register_player(playerData)
		
		# Register the new player with all existing clients
		for curPlayerId in GameData.players:
			ClientNetwork.register_player_from_raw_data(curPlayerId, playerData)
		
		# Catch the new player up on who is already here
		for curPlayerId in GameData.players:
			if curPlayerId != playerId:
				var player = GameData.get_player(curPlayerId)
				ClientNetwork.register_player(playerId, player)
		
		# If there is no host, make this player the host
		# That will trigger a player update
		if GameData.get_host() == null:
			make_host(playerId)
		# Update player data
		else:
			ClientNetwork.update_game_data()


func make_host(playerId: int):
	print("Server: Making %d host" % playerId)
	# If we have an existing host, make them no longer the host
	var curHost := GameData.get_host() as PlayerData
	if curHost != null:
		curHost.set_is_host(false)
	
	# Set the new player as host
	var playerInfo := GameData.get_player(playerId) as PlayerData
	playerInfo.set_is_host(true)
	
	ClientNetwork.update_players()


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
		
		if not get_tree().is_connected("network_peer_disconnected", self, "_player_disconnected"):
			get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
		
		if not get_tree().is_connected("network_peer_connected", self, "_player_connected"):
			get_tree().connect("network_peer_connected", self, "_player_connected")	
		
		print("Server started.")
		return true
	else:
		print("Failed to host game: %d" % result)
		return false


func change_player_type(playerId: int, playerType: int):
	rpc_id(SERVER_ID, "on_change_player_type", playerId, playerType)


remotesync func on_change_player_type(playerId: int, playerType: int):
	if GameData.currentGame == null:
		var player = GameData.get_player(playerId) as PlayerData
		if player != null:
			player.set_type(playerType)
			
			ClientNetwork.update_players()
		else:
			print("ERROR: on_change_player_type() player not found for ID: %d" % playerId)
	else:
		print("WARN: not allowed to change player type while in game")


func randomize_teams():
	rpc("on_randomize_teams")


func kick_player(playerId: int):
	rpc_id(SERVER_ID, "on_kick_player", playerId)


remote func on_kick_player(playerId: int):
	ClientNetwork.force_disconnect(playerId, "You have been kicked from the server")


remotesync func on_randomize_teams():
	if not get_tree().is_network_server():
		return
	
	var playerIds = GameData.players.keys()
	
	var mapId = GameData.general[GameData.GENERAL_MAP]
	var mode = Maps.get_mode_for_map(mapId)
	
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
	
	ClientNetwork.update_players()
