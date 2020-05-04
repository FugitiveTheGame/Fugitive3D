extends "BaseNetwork.gd"

signal create_player(playerId)
signal update_player(playerId)
signal update_game_data(generalData)
signal start_game
signal start_lobby_countdown
signal lost_connection_to_server

var localPlayerName: String

func _ready():
	get_tree().connect('connected_to_server', self, 'on_connected_to_server')
	get_tree().connect('server_disconnected', self, 'on_disconnected_from_server')
	get_tree().connect('connection_failed', self, 'on_connection_failed')

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
	reset_network()


func on_disconnected_from_server():
	print("Disconnected from server.")
	reset_network()
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
	# Unready all players when we start the game
	for player in GameData.get_players():
		player.set_lobby_ready(false)
	
	emit_signal("start_game")


func is_local_player(playerId: int) -> bool:
	return playerId == get_tree().get_network_unique_id()


func force_disconnect(playerId: int):
	rpc_id(playerId, "on_force_disconnect")


remote func on_force_disconnect():
	print("Force disconnect from server")
	on_disconnected_from_server()
