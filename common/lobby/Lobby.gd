extends Control
class_name Lobby


func _ready():
	ClientNetwork.connect("create_player", self, "create_player")
	ClientNetwork.connect("remove_player", self, "remove_player")


func create_player(playerId: int):
	var existingPlayer := find_player_node(playerId)
	if existingPlayer != null:
		return
	
	print("Creating player in lobby")
	
	var namePlateScene = preload("res://common/lobby/NamePlate.tscn")
	
	var namePlateNode = namePlateScene.instance()
	namePlateNode.set_network_master(playerId)
	namePlateNode.set_name(str(playerId))
	
	var player = GameData.players[playerId]
	namePlateNode.get_node("Name").text = player[GameData.PLAYER_NAME]
	
	$Players.add_child(namePlateNode)


func find_player_node(playerId: int) -> Control:
	var playerNode: Control = null
	
	var nodeName := str(playerId)
	for child in $Players.get_children():
		if child.name == nodeName:
			playerNode = child
			break
	
	return playerNode


func remove_player(playerId: int):
	var node := find_player_node(playerId)
	if node != null:
		$Players.remove_child(node)
	else:
		print("Lobby: remove_player: failed to find node for player: %d" % playerId)
