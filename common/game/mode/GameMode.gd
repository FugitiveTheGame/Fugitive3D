extends Spatial
class_name GameMode

signal preconfigure_complete

var localPlayer: Player
var players = {}


func get_player(playerId: int) -> Player:
	if players.has(playerId):
		return players[playerId]
	else:
		return null


func _enter_tree():
	ClientNetwork.connect("remove_player", self, "remove_player")
	
	GameData.currentGame = self


func _ready():
	print("Entering game")
	get_tree().paused = true
	
	load_map()
	
	call_deferred("pre_configure")


func _exit_tree():
	ClientNetwork.disconnect("remove_player", self, "remove_player")
	
	GameData.currentGame = null
	GameData.currentMap = null
	
	# Make sure we can't leave the GameMode without unpausing the game
	get_tree().paused = false


func load_map():
	var mapId = GameData.general[GameData.GENERAL_MAP]
	var mapData = Maps.directory[mapId]
	var mapPath = mapData[Maps.MAP_PATH]
	var scene := load(mapPath)
	var map = scene.instance()
	add_child(map)
	GameData.currentMap = map


func pre_configure():
	call_deferred("emit_signal", "preconfigure_complete")


func get_team_name(teamid: int) -> String:
	print("get_team_name() MUST BE OVERRIDEN")
	assert(false)
	return "null"
