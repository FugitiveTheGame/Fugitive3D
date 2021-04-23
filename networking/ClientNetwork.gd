extends "res://networking/BaseNetwork.gd"

signal create_player(playerId)
signal update_player(playerId)
signal update_game_data(generalData)
signal start_game
signal start_lobby_countdown
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
	get_tree().connect('connected_to_server', self, 'on_connected_to_server')
	get_tree().connect('server_disconnected', self, 'on_disconnected_from_server')
	get_tree().connect('connection_failed', self, 'on_connection_failed')


func _exit_tree():
	get_tree().disconnect('connected_to_server', self, 'on_connected_to_server')
	get_tree().disconnect('server_disconnected', self, 'on_disconnected_from_server')
	get_tree().disconnect('connection_failed', self, 'on_connection_failed')


func join_game(serverIp: String, serverPort: int, playerName: String) -> bool:
	self.localPlayerName = playerName
	
	var peer := NetworkedMultiplayerENet.new()
	peer.compression_mode = 4
	var result = peer.create_client(serverIp, serverPort)
	
	if result == OK:
		get_tree().set_network_peer(peer)
		print("Connecting to server...")
		return true
	else:
		return false


func on_connected_to_server():
	print("Connected to server.")


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


remote func on_register_player(player: Dictionary):
	var playerId = player.id
	var playerName = player.name
	
	#print("on_register_player: %d - %s" % [playerId, playerName] )
	print("on_register_player" )
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


remotesync func on_update_player(playersDictionary: Dictionary, sequenceNumber: int):
	GameData.lock.lock()
	
	if playerDataSequence <= sequenceNumber or sequenceNumber <= 0:
		playerDataSequence = sequenceNumber
		print("Updating players: new %d" % [playerDataSequence])
		for playerId in playersDictionary:
			var playerInfoDictionary = playersDictionary[playerId]
			var updated = GameData.update_player_from_raw_data(playerInfoDictionary)
			# Only send update event if this player actually updated
			if updated or get_tree().is_network_server(): # Server always dispatches updates
				emit_signal("update_player", playerInfoDictionary.id)
	else:
		print("Old player data received, discarding. old %d / new %d" % [playerDataSequence, sequenceNumber])
	
	GameData.lock.unlock()

# Send local game data to all clients
func update_game_data():
	var sequenceNumber := getNextSequence(gameDataSequence)
	rpc("on_update_game_data", GameData.general, sequenceNumber)


remotesync func on_update_game_data(generalData: Dictionary, sequenceNumber: int):
	GameData.lock.lock()
	
	print("on_update_game_data: new seq: " + str(sequenceNumber) + " cur seq: " + str(gameDataSequence))
	if gameDataSequence <= sequenceNumber or sequenceNumber <= 0:
		gameDataSequence = sequenceNumber
		print("Updating game data: new %d" % [gameDataSequence])
		GameData.update_general(generalData)
		emit_signal("update_game_data", GameData.general)
	else:
		print("Old game data received, discarding. old %d / new %d" % [gameDataSequence, sequenceNumber])
	
	GameData.lock.unlock()


func start_lobby_countdown():
	rpc("on_start_lobby_countdown")


remotesync func on_start_lobby_countdown():
	emit_signal("start_lobby_countdown")


# Only the host should call this
func start_game():
	# The server will take care of it's self, tell all other players to start
	for playerId in GameData.players:
		if playerId != ServerNetwork.SERVER_ID:
			rpc_id(playerId, "on_start_game")


remotesync func on_start_game():
	# Unready all players when we start the game
	print("Unready all lobby players")
	for player in GameData.get_players():
		player.set_lobby_ready(false)
	
	emit_signal("start_game")


func is_local_player(playerId: int) -> bool:
	return playerId == get_tree().get_network_unique_id()


func force_disconnect(playerId: int, message: String):
	rpc_id(playerId, "on_force_disconnect", message)


remote func on_force_disconnect(message: String):
	print("Force disconnect from server: %s" % message)
	handle_disconnect_from_server(message)


func has_disconnect_reason() -> bool:
	return disconnectReason != null and not disconnectReason.empty()


func consume_disconnect_reason() -> String:
	var message = str(disconnectReason)
	disconnectReason = null
	return message


func reset_network():
	.reset_network()
	
	gameDataSequence = 0
	playerDataSequence = 0
