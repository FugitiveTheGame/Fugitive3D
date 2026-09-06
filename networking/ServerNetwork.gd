extends Node

const SERVER_PORT := 31000
const SERVER_ID := 1
var SERVER_REPOSITORY_URL: String
const MAX_PLAYERS := 10

# ENet drops a peer that misses acks for this long. Map loads block the main
# thread for many seconds, so the default 5s is far too aggressive.
const PEER_TIMEOUT_MIN_MS := 60_000
const PEER_TIMEOUT_MAX_MS := 120_000

var is_joinable := false


# Set to true to point at a locally running instance of the ServerRepository
const debug_local := false
func _init():
	if debug_local:
		SERVER_REPOSITORY_URL = "http://127.0.0.1:8080"
	else:
		SERVER_REPOSITORY_URL = "http://repository.fugitivethegame.online"


func _exit_tree():
	if multiplayer.peer_disconnected.is_connected(_player_disconnected):
		multiplayer.peer_disconnected.disconnect(_player_disconnected)

	if multiplayer.peer_connected.is_connected(_player_connected):
		multiplayer.peer_connected.disconnect(_player_connected)


func _player_connected(id):
	print("SERVER: Player connected: " + str(id))
	# Loading a map blocks the main thread well past ENet's 5s default
	# timeout, so a peer that is merely busy gets dropped mid-load
	var peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if peer != null:
		peer.get_peer(id).set_timeout(32, PEER_TIMEOUT_MIN_MS, PEER_TIMEOUT_MAX_MS)


func _player_disconnected(id):
	print("SERVER: Player connected: " + str(id))
	# If it was the host who left, and there are any
	# players left, pick the first one and make them host
	if not GameData.players.is_empty():
		# No host, make the first player the new host
		if GameData.get_host() == null:
			var newHost = GameData.players.values().front()
			if newHost != null:
				make_host(newHost.get_id())


func change_map(map_id: String):
	rpc_id(SERVER_ID, "on_change_map", map_id)


@rpc("any_peer") func on_change_map(map_id: String):
	if GameData.currentGame == null:
		GameData.general[GameData.GENERAL_MAP] = map_id
		
		ClientNetwork.update_game_data()
	else:
		print("WARN: Not allowed to change map during game")


# Called by clients when they connect
func register_self(playerId: int, platformType: int, playerName: String, gameVersion: int):
	rpc_id(SERVER_ID, "on_register_self", playerId, platformType, playerName, gameVersion)


@rpc("any_peer") func on_register_self(playerId: int, platformType: int, playerName: String, gameVersion: int):
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
	return Utils.has_active_network_peer(multiplayer) \
		and multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED


func host_game(port: int = SERVER_PORT) -> bool:
	# Clear out any old state
	ClientNetwork.reset_network()
	
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(port, MAX_PLAYERS)
	if result == OK:
		peer.host.compress(ENetConnection.COMPRESS_ZSTD)
		multiplayer.multiplayer_peer = peer

		GameData.general[GameData.GENERAL_SEED] = Time.get_unix_time_from_system()

		if not multiplayer.peer_disconnected.is_connected(_player_disconnected):
			multiplayer.peer_disconnected.connect(_player_disconnected)

		if not multiplayer.peer_connected.is_connected(_player_connected):
			multiplayer.peer_connected.connect(_player_connected)
		
		print("Server started.")
		return true
	else:
		print("Failed to host game: %d" % result)
		return false


func change_player_type(playerId: int, playerType: int):
	rpc_id(SERVER_ID, "on_change_player_type", playerId, playerType)


@rpc("any_peer", "call_local") func on_change_player_type(playerId: int, playerType: int):
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


@rpc("any_peer") func on_kick_player(playerId: int):
	ClientNetwork.force_disconnect(playerId, "You have been kicked from the server")


@rpc("any_peer", "call_local") func on_randomize_teams():
	if not multiplayer.is_server():
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
	while not teamLayout.is_empty() and not playerIds.is_empty():
		var teamCount = teamLayout.pop_front()
	
		while teamCount > 0 and not playerIds.is_empty():
			teamCount -= 1
			
			var playerId = playerIds.pop_front()
			change_player_type(playerId, teamId)
		
		teamId += 1
	
	ClientNetwork.update_players()
