extends Spatial


func _ready():
	print("Entering game")
	get_tree().paused = true
	
	ClientNetwork.connect("remove_player", self, "remove_player")
	
	pre_configure()


func remove_player(playerId: int):
	var playerNode = $Players.get_node(str(playerId))
	playerNode.queue_free()


func pre_configure():
	var order := 0
	var sortedPlayers = []
	for playerId in GameData.players:
		sortedPlayers.push_back(playerId)
	
	sortedPlayers.sort()
	
	for playerId in sortedPlayers:
		spawn_player(playerId, order)
		order += 1
	
	if not get_tree().is_network_server():
		print("Reporting ready: %d" % get_tree().get_network_unique_id())
		# Report that this client is done
		rpc_id(ServerNetwork.SERVER_ID, "on_client_ready", get_tree().get_network_unique_id())


func spawn_player(playerId, order):
	print("Creating player game object")
	
	var player = GameData.players[playerId]
	var playerName = player[GameData.PLAYER_NAME]
	
	var node: Node
	if get_tree().get_network_unique_id() == playerId:
		node = create_player_node()
	else:
		node = create_base_node()
	
	node.set_network_master(playerId)
	node.set_name(str(playerId))
	
	node.translation.x = 1 * (order + 1)
	node.translation.y = 1
	
	#node.get_node("NameLabel").text = playerName
	
	$Players.add_child(node)


func create_base_node() -> Node:
	var scene = preload("res://common/game/player/Player.tscn")
	return scene.instance()


func create_player_node() -> Node:
	print("MUST OVERRIDE create_player_node()")
	assert(false)
	return null


remotesync func on_pre_configure_complete():
	print("All clients are configured. Starting the game.")
	get_tree().paused = false
