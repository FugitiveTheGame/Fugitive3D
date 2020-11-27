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
	
	print("on_register_player: %d - %s" % [playerId, playerName] )
	GameData.add_player_from_raw_data(player)
	emit_signal("create_player", playerId)
	print("Total players: %d" % GameData.players.size())


func update_player(playerData: PlayerData):
	rpc("on_update_player", playerData.player_data_dictionary)


remotesync func on_update_player(playerInfoDictionary: Dictionary):
	GameData.update_player_from_raw_data(playerInfoDictionary)
	emit_signal("update_player", playerInfoDictionary.id)


func update_game_data(generalData: Dictionary, sequenceNumber: int):
	rpc("on_update_game_data", generalData, sequenceNumber)


remotesync func on_update_game_data(generalData: Dictionary, sequenceNumber: int):
	print("on_update_game_data: new seq: " + str(sequenceNumber) + " cur seq: " + str(sequenceNumber))
	if gameDataSequence < sequenceNumber:
		gameDataSequence = sequenceNumber
		GameData.update_general(generalData)
		emit_signal("update_game_data", GameData.general)
	else:
		print("Old game data received, discarding.")


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
