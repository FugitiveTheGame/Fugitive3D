extends Node

var players = {}

const PLAYER_ID = "id"
const PLAYER_NAME = "name"
const PLAYER_TYPE = "type"
func create_new_player(playerId: int, playerName: String, playerType: int) -> Dictionary:
	return { PLAYER_ID: playerId, PLAYER_NAME: playerName, PLAYER_TYPE: playerType }

func add_player(playerId: int, playerName: String, playerType: int):
	var newPlayer = create_new_player(playerId, playerName, playerType)
	self.players[playerId] = newPlayer

func reset():
	self.players = {}
