extends Node

const TYPE_FLAT := "flat"
const TYPE_VR := "vr"
const TYPE_SERVER := "server"

const MAP_NAME := "name"
const MAP_DESCRIPTION := "description"
const MAP_MODE := "mode"
const MAP_SIZE := "size"
const MAP_PATH := "path"
const MAP_TEAM_SIZES := "team_sizes"

const MODE_NAME := "name"
const MODE_TEAM_RESOLVER_PATH := "team_resolver"
const MODE_TEAM_RESOLVER := "team_resolver_object"
const MODE_RULES := "rules"
const MODE_CONTROLS := "controls"
const MODE_CONTROLS_FLAT := "flat"
const MODE_CONTROLS_FLAT_MOBILE := "flat_mobile"
const MODE_CONTROLS_VR := "vr"

var directory = []
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
	directory = data.maps
	
	modes = data.modes
	for modeName in modes:
		var mode = modes[modeName]
		mode[MODE_TEAM_RESOLVER] = load(mode[MODE_TEAM_RESOLVER_PATH]).new()


func get_team_sizes_for_map(mapId: int) -> Array:
	var map = directory[mapId]
	return map[MAP_TEAM_SIZES]


func get_mode_for_map(mapId: int) -> Dictionary:
	var map = directory[mapId]
	return self.modes[map[MAP_MODE]]


func get_game_scene(mapId: int, type: String) -> String:
	var mode = get_mode_for_map(mapId)
	return mode.game_scene[type]


func get_team_resolver(mapId: int):
	var mode = get_mode_for_map(mapId)
	return mode[MODE_TEAM_RESOLVER]


func get_team_name(mapId: int, teamId: int) -> String:
	var mode = get_mode_for_map(mapId)
	return mode[MODE_TEAM_RESOLVER].get_team_name(teamId)
