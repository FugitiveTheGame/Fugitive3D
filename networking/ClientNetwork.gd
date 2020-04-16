extends "BaseNetwork.gd"

signal create_player
signal start_game

var localPlayerName: String

func join_game(serverIp: String, serverPort: int, playerName: String) -> bool:
	get_tree().connect('connected_to_server', self, 'on_connected_to_server')
	
	self.localPlayerName = playerName
	
	var peer = NetworkedMultiplayerENet.new()
	var result = peer.create_client(serverIp, serverPort)
	
	if result == OK:
		get_tree().set_network_peer(peer)
		print("Connecting to server...")
		return true
	else:
		return false


func on_connected_to_server():
	print("Connected to server.")


func register_player(recipientId: int, playerId: int, playerName: String, playerType: int):
	rpc_id(recipientId, "on_register_player", playerId, playerName, playerType)


remote func on_register_player(playerId: int, playerName: String, playerType: int):
	print("on_register_player: %d - %s" % [playerId, playerName] )
	
	GameData.add_player(playerId, playerName, playerType)
	emit_signal("create_player", playerId)
	print("Total players: %d" % GameData.players.size())


func start_game():
	rpc("on_start_game")


remotesync func on_start_game():
	emit_signal("start_game")
