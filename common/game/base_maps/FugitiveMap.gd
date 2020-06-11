extends "res://common/game/base_maps/BaseMap.gd"
class_name FugitiveMap

onready var winZones := get_tree().get_nodes_in_group(Groups.WIN_ZONE)
onready var players := $Players

onready var roads := get_roads()
onready var mapBoundingBox: AABB


func _ready():
	var bbArea := $Roads.find_node("MapBoundingBox") as CollisionShape
	var bbShape := bbArea.shape as BoxShape
	mapBoundingBox = AABB(bbArea.global_transform.origin, bbShape.extents * 2.0)


func get_roads() -> Array:
	var roads = []
	for child in $Roads.get_children():
		if child is Street:
			roads.push_back(child)
	return roads


func get_hider_spawns() -> Array:
	return $HiderSpawns.get_children()


func get_seeker_spawns() -> Array:
	return $SeekerSpawns.get_children()


func get_players():
	return $Players


# Count down to start when everyone is ready
func get_countdown_timer():
	return $StartTimer


# Count down for the headstart phase of the game to end
func get_headstart_timer():
	return $HeadstartTimer


# Time limit for the playing phases of the gme
func get_timelimit_timer():
	return $GameTimer


func get_win_zones() -> Array:
	return winZones
