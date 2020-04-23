extends Spatial
class_name FugitiveMap

onready var winZones := get_tree().get_nodes_in_group(Groups.WIN_ZONE)
onready var players := $Players


func get_hider_spawns() -> Array:
	return $HiderSpawns.get_children()


func get_seeker_spawns() -> Array:
	return $SeekerSpawns.get_children()


func get_players():
	return $Players


# Time limit for the playing phases of the gme
func get_timelimit_timer():
	return $GameTimer


# Count down for the headstart phase of the game to end
func get_headstart_timer():
	return $HeadstartTimer


# Count down to start when everyone is ready
func get_countdown_timer():
	return $StartTimer


func get_win_zones() -> Array:
	return winZones
