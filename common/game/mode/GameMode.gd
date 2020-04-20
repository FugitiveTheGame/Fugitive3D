extends Spatial
class_name GameMode


func get_player(playerId: int) -> Player:
	print("GameMode: get_player() MUST BE OVERRIDDEN")
	assert("false")
	return null


func set_map(map: Node):
	add_child(map)
	
	GameData.currentMap = map


func _enter_tree():
	GameData.currentGame = self


func _exit_tree():
	GameData.currentGame = null
	GameData.currentMap = null
