extends Control
class_name Lobby


func _ready():
	ClientNetwork.connect("create_player", self, "create_player")
	ClientNetwork.connect("update_player", self, "update_player")
	ClientNetwork.connect("remove_player", self, "remove_player")


func create_player(playerId: int):
	var existingPlayer := find_player_node(playerId)
	if existingPlayer != null:
		return
	
	print("Creating player in lobby")
	
	var player = GameData.players[playerId]
	
	var playerListItem = preload("res://common/lobby/PlayerListItem.tscn")
	
	var playerNode = playerListItem.instance()
	playerNode.set_network_master(playerId)
	playerNode.set_name(str(playerId))
	playerNode.populate(player)
	
	$Players.add_child(playerNode)


func find_player_node(playerId: int) -> Control:
	var playerNode: Control = null
	
	var nodeName := str(playerId)
	for child in $Players.get_children():
		if child.name == nodeName:
			playerNode = child
			break
	
	return playerNode


func update_player(playerId: int):
	var player = GameData.players[playerId]
	
	var node := find_player_node(playerId)
	if node != null:
		node.populate(player)
	else:
		print("update_player() - Failed to get player node")


func remove_player(playerId: int):
	var node := find_player_node(playerId)
	if node != null:
		$Players.remove_child(node)
	else:
		print("Lobby: remove_player: failed to find node for player: %d" % playerId)
