extends Node

enum PlayerType { Hider, Seeker, Random, Server, Unset }

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


func get_current_player():
	var id := get_tree().get_network_unique_id()
	if players.has(id):
		return players[id]
	else:
		return null


func get_current_player_type() -> int:
	var curPlayer = get_current_player()
	if curPlayer != null:
		return curPlayer[PLAYER_TYPE]
	else:
		return PlayerType.Unset
