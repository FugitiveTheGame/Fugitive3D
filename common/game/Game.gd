extends Spatial

var game: Spatial
var players: Node

func _ready():
	print("Entering game")
	get_tree().paused = true
	
	load_map()
	
	ClientNetwork.connect("remove_player", self, "remove_player")
	
	pre_configure()


func load_map():
	# TODO: This needs to be made dynamic of course
	var scene := preload("res://common/game/maps/test_map_00/TestMap00.tscn")
	game = scene.instance()
	add_child(game)
	players = game.find_node("Players")


func remove_player(playerId: int):
	var playerNode = players.get_node(str(playerId))
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
	var playerName := player[GameData.PLAYER_NAME] as String
	var playerType := player[GameData.PLAYER_TYPE] as int
	
	var node: Node
	match playerType:
		0:
			node = create_player_seeker_node()
		1:
			node = create_player_hider_node()
	
	node.set_network_master(playerId)
	node.set_name(str(playerId))
	
	if get_tree().get_network_unique_id() != playerId:
		node.set_not_local_player()
	else:
		node.set_is_local_player()
	
	node.configure(playerName)
	
	# Hacky spawn position
	node.translation.x = 1 * (order + 1)
	node.translation.y = 1
	
	players.add_child(node)


func create_player_seeker_node() -> Node:
	var scene = preload("res://common/game/player/seeker/Seeker.tscn")
	return scene.instance()


func create_player_hider_node() -> Node:
	var scene = preload("res://common/game/player/hider/Hider.tscn")
	return scene.instance()


remotesync func on_pre_configure_complete():
	print("All clients are configured. Starting the game.")
	get_tree().paused = false


