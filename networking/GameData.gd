extends Node

enum PlayerType { Hider, Seeker, Random, Server, Unset }

const PLAYER_ID = "id"
const PLAYER_NAME = "name"
const PLAYER_TYPE = "type"
const PLAYER_HOST = "host"

var players = {}


const GENERAL_MAP = "map"
const GENERAL_SEED = "shared_seed"

var general = {
	GENERAL_MAP : 0,
	GENERAL_SEED : 0
}


func get_players() -> Array:
	return players.values()


func get_player(playerId: int):
	if players.has(playerId):
		return players[playerId]
	else:
		return null


func create_new_player(playerId: int, playerName: String, playerType: int) -> Dictionary:
	return {
		PLAYER_ID: playerId,
		PLAYER_NAME: playerName,
		PLAYER_TYPE: playerType,
		PLAYER_HOST: false
	}


func add_player(newPlayer: Dictionary) -> bool:
	var playerId = newPlayer[PLAYER_ID]
	if not self.players.has(playerId):
		self.players[playerId] = newPlayer
		return true
	else:
		return false


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


func update_player(player):
	var playerId = player[PLAYER_ID]
	players[playerId] = player
