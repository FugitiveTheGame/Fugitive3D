extends Node

const TYPE_FLAT := "flat"
const TYPE_VR := "vr"
const TYPE_SERVER := "server"

const MAP_ID := "id"
const MAP_NAME := "name"
const MAP_DESCRIPTION := "description"
const MAP_MODE := "mode"
const MAP_SIZE := "size"
const MAP_PATH := "path"
const MAP_HIDE := "hide"
const MAP_TEAM_SIZES := "team_sizes"

const MODE_NAME := "name"
const MODE_TEAM_RESOLVER_PATH := "team_resolver"
const MODE_TEAM_RESOLVER := "team_resolver_object"
const MODE_RULES := "rules"
const MODE_CONTROLS := "controls"
const MODE_CONTROLS_FLAT := "flat"
const MODE_CONTROLS_FLAT_MOBILE := "flat_mobile"
const MODE_CONTROLS_VR := "vr"

var directory = {}
var modes = {}

func _ready():
	var file = File.new()
	if file.open('res://common/game/maps/map_directory.json', File.READ) != 0:
		print("Error opening file")
		return
	
	var serialized = file.get_as_text()
	var parsed = JSON.parse(serialized)
	file.close()
	
	var data = parsed.result
	for map in data.maps:
		directory[map.id] = map
	
	modes = data.modes
	for modeName in modes:
		var mode = modes[modeName]
		mode[MODE_TEAM_RESOLVER] = load(mode[MODE_TEAM_RESOLVER_PATH]).new()
	
	# Init map id to the first map, this is a bunch of code that gets angry if this
	# is not a valid ID at all times :(
	if GameData.general[GameData.GENERAL_MAP] == null or GameData.general[GameData.GENERAL_MAP] == "":
		GameData.general[GameData.GENERAL_MAP] = directory.values()[0].id


func get_team_sizes_for_map(mapId: String) -> Array:
	var map = directory[mapId]
	return map[MAP_TEAM_SIZES]


func get_mode_for_map(mapId: String) -> Dictionary:
	var map = directory[mapId]
	return self.modes[map[MAP_MODE]]


func get_game_scene(mapId: String, type: String) -> String:
	var mode = get_mode_for_map(mapId)
	return mode.game_scene[type]


func get_team_resolver(mapId: String):
	var mode = get_mode_for_map(mapId)
	return mode[MODE_TEAM_RESOLVER]


func get_team_name(mapId: String, teamId: int) -> String:
	var mode = get_mode_for_map(mapId)
	return mode[MODE_TEAM_RESOLVER].get_team_name(teamId)
