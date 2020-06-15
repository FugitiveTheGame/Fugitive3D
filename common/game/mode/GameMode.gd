extends Spatial
class_name GameMode

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
	GameData.currentMap.queue_free()
	GameData.currentMap = null
	queue_free()


func load_map():
	var mapData = Maps.directory[GameData.general[GameData.GENERAL_MAP]]
	var mapPath = mapData[Maps.MAP_PATH]
	var scene := load(mapPath)
	var map = scene.instance()
	add_child(map)
	GameData.currentMap = map


func pre_configure():
	pass


func get_team_name(teamid: int) -> String:
	print("get_team_name() MUST BE OVERRIDEN")
	assert(false)
	return "null"
