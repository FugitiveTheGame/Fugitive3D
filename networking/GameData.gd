extends Node


var players = {}

var currentGame: GameMode = null
var currentMap = null

const GENERAL_MAP = "map"
const GENERAL_SEED = "shared_seed"

var general = {
	GENERAL_MAP : "",
	GENERAL_SEED : 0
}

var lock := Mutex.new()


func remove_player(playerId: int):
	players.erase(playerId)


func get_players() -> Array:
	return players.values()


func get_player(playerId: int) -> PlayerData:
	if players.has(playerId):
		return players[playerId] as PlayerData
	else:
		return null


func create_new_player_raw_data(playerId: int, platformType: int, playerName: String, playerType: int) -> Dictionary:
	return {
		id = playerId,
		name = playerName,
		lobby_ready = true,
		type = playerType,
		is_host = false,
		platform_type = platformType
	}

func add_player_from_raw_data(newPlayerDictionary: Dictionary) -> bool:
	var playerId = newPlayerDictionary.id
	if not self.players.has(playerId):
		var newPlayer := PlayerData.new()
		newPlayer.load(newPlayerDictionary)
		
		self.players[playerId] = newPlayer
		return true
	else:
		return false


func reset():
	self.players = {}


func update_general(new_data: Dictionary):
	lock.lock()
	general = new_data
	lock.unlock()


func get_current_player() -> PlayerData:
	var id := get_tree().get_network_unique_id()
	if players.has(id):
		return players[id] as PlayerData
	else:
		return null


func get_current_player_type() -> int:
	var curPlayer := get_current_player()
	if curPlayer != null:
		return curPlayer.get_type()
	else:
		return -1


func get_current_player_id() -> int:
	var curPlayer := get_current_player()
	if curPlayer != null:
		return curPlayer.get_id()
	else:
		return -1


func update_player_from_raw_data(player_data_dictionary: Dictionary):
	var playerId = player_data_dictionary.id
	var player := get_player(playerId)
	if player != null:
		player.load(player_data_dictionary)


func get_host() -> PlayerData:
	var host = null
	
	for player in GameData.players.values():
		var playerData := player as PlayerData
		
		if playerData.get_is_host() == true:
			host = player
			break
	
	return host
