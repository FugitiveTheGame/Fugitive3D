extends "res://networking/BaseNetwork.gd"

signal create_player(playerId)
signal update_player(playerId)
signal game_data_updated(generalData)
signal game_started
signal lobby_countdown_started
signal lost_connection_to_server

var localPlayerName: String
var disconnectReason = null

var gameDataSequence := 0
var playerDataSequence := 0

func getNextSequence(curSequence: int) -> int:
	var newSequence: int
	# Roll over
	if curSequence + 1 < 0:
		newSequence = 0
	else:
		newSequence = curSequence + 1
	
	return newSequence


func _enter_tree():
	multiplayer.connected_to_server.connect(on_connected_to_server)
	multiplayer.server_disconnected.connect(on_disconnected_from_server)
	multiplayer.connection_failed.connect(on_connection_failed)


func _exit_tree():
	super._exit_tree()
	multiplayer.connected_to_server.disconnect(on_connected_to_server)
	multiplayer.server_disconnected.disconnect(on_disconnected_from_server)
	multiplayer.connection_failed.disconnect(on_connection_failed)


func join_game(serverIp: String, serverPort: int, playerName: String) -> bool:
	self.localPlayerName = playerName
	
	var peer := ENetMultiplayerPeer.new()
	var result = peer.create_client(serverIp, serverPort)

	if result == OK:
		peer.host.compress(ENetConnection.COMPRESS_ZSTD)
		multiplayer.multiplayer_peer = peer
		print("Connecting to server...")
		return true
	else:
		return false


func on_connected_to_server():
	print("Connected to server.")
	# Matches the server side: survive the main-thread stall of a map load
	var peer := multiplayer.multiplayer_peer as ENetMultiplayerPeer
	if peer != null:
		peer.get_peer(1).set_timeout(32,
			ServerNetwork.PEER_TIMEOUT_MIN_MS, ServerNetwork.PEER_TIMEOUT_MAX_MS)


func on_connection_failed():
	print("Connection to server failed.")
	call_deferred("reset_network")


func on_disconnected_from_server():
	print("Disconnected from server.")
	handle_disconnect_from_server()


func handle_disconnect_from_server(message := "Connection lost"):
	disconnectReason = message
	call_deferred("reset_network")
	GameAnalytics.error_event(GameAnalytics.ErrorSeverity.ERROR, "Lost connection to server: %s" % message)
	emit_signal("lost_connection_to_server")


func register_player(recipientId: int, player: PlayerData):
	rpc_id(recipientId, "on_register_player", player.player_data_dictionary)


func register_player_from_raw_data(recipientId: int, playerDataDictionary: Dictionary):
	rpc_id(recipientId, "on_register_player", playerDataDictionary)


@rpc("any_peer") func on_register_player(player: Dictionary):
	var playerId = player.id
	var playerName = player.name
	
	print("on_register_player: %d - %s" % [playerId, playerName] )

	GameData.add_player_from_raw_data(player)
	emit_signal("create_player", playerId)
	print("Total players: %d" % GameData.players.size())


# Sends this clients player data to all other clients
func update_players():
	var playerDictionaries := {}
	for playerId in GameData.players:
		playerDictionaries[playerId] = GameData.players[playerId].player_data_dictionary
	
	var sequenceNumber := getNextSequence(playerDataSequence)
	
	print("Sending player update: old %d / new %d" % [playerDataSequence, sequenceNumber])
	
	rpc("on_update_player", playerDictionaries, sequenceNumber)


@rpc("any_peer", "call_local") func on_update_player(playersDictionary: Dictionary, sequenceNumber: int):
	GameData.lock.lock()
	
	if playerDataSequence <= sequenceNumber or sequenceNumber <= 0:
		playerDataSequence = sequenceNumber
		print("Updating players: new %d" % [playerDataSequence])
		for playerId in playersDictionary:
			var playerInfoDictionary = playersDictionary[playerId]
			var updated = GameData.update_player_from_raw_data(playerInfoDictionary)
			# Only send update event if this player actually updated
			if updated or multiplayer.is_server(): # Server always dispatches updates
				emit_signal("update_player", playerInfoDictionary.id)
	else:
		print("Old player data received, discarding. old %d / new %d" % [playerDataSequence, sequenceNumber])
	
	GameData.lock.unlock()

# Send local game data to all clients
func update_game_data():
	var sequenceNumber := getNextSequence(gameDataSequence)
	rpc("on_update_game_data", GameData.general, sequenceNumber)


@rpc("any_peer", "call_local") func on_update_game_data(generalData: Dictionary, sequenceNumber: int):
	GameData.lock.lock()
	
	print("on_update_game_data: new seq: " + str(sequenceNumber) + " cur seq: " + str(gameDataSequence))
	if gameDataSequence <= sequenceNumber or sequenceNumber <= 0:
		gameDataSequence = sequenceNumber
		print("Updating game data: new %d" % [gameDataSequence])
		GameData.update_general(generalData)
		emit_signal("game_data_updated", GameData.general)
	else:
		print("Old game data received, discarding. old %d / new %d" % [gameDataSequence, sequenceNumber])
	
	GameData.lock.unlock()


func start_lobby_countdown():
	rpc("on_start_lobby_countdown")


@rpc("any_peer", "call_local") func on_start_lobby_countdown():
	emit_signal("lobby_countdown_started")


# Only the host should call this
func start_game():
	# The server will take care of it's self, tell all other players to start
	for playerId in GameData.players:
		if playerId != ServerNetwork.SERVER_ID:
			rpc_id(playerId, "on_start_game")


@rpc("any_peer", "call_local") func on_start_game():
	# Unready all players when we start the game
	print("Unready all lobby players")
	for player in GameData.get_players():
		player.set_lobby_ready(false)
	
	emit_signal("game_started")


func is_local_player(playerId: int) -> bool:
	return playerId == multiplayer.get_unique_id()


func force_disconnect(playerId: int, message: String):
	rpc_id(playerId, "on_force_disconnect", message)


@rpc("any_peer") func on_force_disconnect(message: String):
	print("Force disconnect from server: %s" % message)
	handle_disconnect_from_server(message)


func has_disconnect_reason() -> bool:
	return disconnectReason != null and not disconnectReason.is_empty()


func consume_disconnect_reason() -> String:
	var message = str(disconnectReason)
	disconnectReason = null
	return message


func reset_network():
	super.reset_network()
	
	gameDataSequence = 0
	playerDataSequence = 0
