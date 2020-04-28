extends "BaseNetwork.gd"

signal create_player(playerId)
signal update_player(playerId)
signal update_game_data(generalData)
signal start_game
signal start_lobby_countdown
signal lost_connection_to_server

var localPlayerName: String

func join_game(serverIp: String, serverPort: int, playerName: String) -> bool:
	get_tree().connect('connected_to_server', self, 'on_connected_to_server')
	get_tree().connect('server_disconnected', self, 'on_disconnected_from_server')
	
	self.localPlayerName = playerName
	
	var peer := NetworkedMultiplayerENet.new()
	var result = peer.create_client(serverIp, serverPort)
	
	if result == OK:
		get_tree().set_network_peer(peer)
		print("Connecting to server...")
		return true
	else:
		return false


func on_connected_to_server():
	print("Connected to server.")


func on_disconnected_from_server():
	print("Disconnected from server.")
	reset_network()
	emit_signal("lost_connection_to_server")

	get_tree().disconnect('connected_to_server', self, 'on_connected_to_server')
	get_tree().disconnect('server_disconnected', self, 'on_disconnected_from_server')


func register_player(recipientId: int, player: Dictionary):
	rpc_id(recipientId, "on_register_player", player)


remote func on_register_player(player: Dictionary):
	var playerId = player[GameData.PLAYER_ID]
	var playerName = player[GameData.PLAYER_NAME]
	
	print("on_register_player: %d - %s" % [playerId, playerName] )
	GameData.add_player(player)
	emit_signal("create_player", playerId)
	print("Total players: %d" % GameData.players.size())


func update_player(playerInfo):
	rpc("on_update_player", playerInfo)


remotesync func on_update_player(playerInfo):
	GameData.update_player(playerInfo)
	emit_signal("update_player", playerInfo[GameData.PLAYER_ID])


func update_game_data():
	rpc("on_update_game_data", GameData.general)


remote func on_update_game_data(generalData):
	GameData.general = generalData
	emit_signal("update_game_data", GameData.general)


func start_lobby_countdown():
	rpc("on_start_lobby_countdown")


remotesync func on_start_lobby_countdown():
	emit_signal("start_lobby_countdown")


func start_game():
	rpc("on_start_game")


remotesync func on_start_game():
	emit_signal("start_game")


func is_local_player(playerId: int) -> bool:
	return playerId == get_tree().get_network_unique_id()
