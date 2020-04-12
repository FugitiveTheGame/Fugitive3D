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


func get_game_timer():
	return $GameTimer


func start_game_timer():
	$GameTimer.start()


func get_headstart_timer():
	return $HeadstartTimer


func get_start_timer():
	return $StartTimer


func get_win_zones() -> Array:
	return winZones
