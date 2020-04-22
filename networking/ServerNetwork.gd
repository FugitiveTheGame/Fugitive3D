extends Node

const SERVER_PORT := 31000
const SERVER_ID := 1
const SERVER_REPOSITORY_URL := "http://repository.fugitivethegame.online:8080"
const MAX_PLAYERS := 15


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
			make_host(newHost[GameData.PLAYER_ID])


# Called by clients when they connect
func register_self(playerId: int, playerName: String):
	rpc_id(SERVER_ID, "on_register_self", playerId, playerName)


remote func on_register_self(playerId, playerName):
	var playerType: int
	if GameData.players.size() == 0:
		playerType = GameData.PlayerType.Seeker
	else:
		playerType = GameData.PlayerType.Hider
	
	var playerData = GameData.create_new_player(playerId, playerName, playerType)
	
	# Register this client with the server
	ClientNetwork.on_register_player(playerData)
	
	# Register the new player with all existing clients
	for curPlayerId in GameData.players:
		ClientNetwork.register_player(curPlayerId, playerData)
	
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
	var playerInfo = GameData.get_player(playerId)
	playerInfo[GameData.PLAYER_HOST] = true
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
	var player = GameData.get_player(playerId)
	if player != null:
		player[GameData.PLAYER_TYPE] = playerType
		ClientNetwork.update_player(player)
	else:
		print("ERROR: on_change_player_type() player not found for ID: %d" % playerId)
