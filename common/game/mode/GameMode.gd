extends Spatial
class_name GameMode

var localPlayer: Player
var players = {}


func get_player(playerId: int) -> Player:
	return players[playerId]


func _ready():
	print("Entering game")
	get_tree().paused = true
	
	load_map()
	
	ClientNetwork.connect("remove_player", self, "remove_player")
	
	call_deferred("pre_configure")


func load_map():
	var mapData = Maps.directory[GameData.general[GameData.GENERAL_MAP]]
	var mapPath = mapData[Maps.MAP_PATH]
	var scene := load(mapPath)
	var map = scene.instance()
	add_child(map)
	GameData.currentMap = map


func pre_configure():
	pass


func _enter_tree():
	GameData.currentGame = self


func _exit_tree():
	GameData.currentGame = null
	GameData.currentMap = null


func get_team_name(teamid: int) -> String:
	print("get_team_name() MUST BE OVERRIDEN")
	assert(false)
	return "null"
