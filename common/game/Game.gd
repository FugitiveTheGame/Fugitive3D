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


# If a player has disconnected, remove them from the world
func remove_player(playerId: int):
	var playerNode = players.get_node(str(playerId))
	playerNode.queue_free()


# Pre-game configuration
# Create all of the players and entities
# This has to be completed on all clients before the game can start
# Once completed, notify the server that we are done
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


# Spawn an individual player for the local client
func spawn_player(playerId, order):
	print("Creating player game object")
	
	# Extract the player data
	var player = GameData.players[playerId]
	var playerName := player[GameData.PLAYER_NAME] as String
	var playerType := player[GameData.PLAYER_TYPE] as int
	
	# This is the node for the PlayerController
	var pcNode: Node
	
	# Create the player controller for the local player
	if get_tree().get_network_unique_id() == playerId:
		match playerType:
			0:
				pcNode = create_player_seeker_node()
			1:
				pcNode = create_player_hider_node()
	# Create the player controller for all remote players
	else:
		match playerType:
			0:
				pcNode = create_remote_seeker_node()
			1:
				pcNode = create_remote_hider_node()
	
	pcNode.set_network_master(playerId)
	pcNode.set_name(str(playerId))
	
	# Final setup and config for the player
	var playerNode = pcNode.get_node("Player")
	playerNode.configure(playerName)
	
	# Hacky spawn position
	pcNode.translation.x = 1 * (order + 1)
	pcNode.translation.y = 1
	
	# Add the PlayerController to the player's node in the game scene
	players.add_child(pcNode)


# When all clients have reported that they have finished setting up the gmae
# The server calls this on all clients telling them to start the game
remotesync func on_pre_configure_complete():
	print("All clients are configured. Starting the game.")
	get_tree().paused = false


####################################
# create_remote_xxx_node()
# These methods are used for creating players who are not
# localy controlled by this machine.
func create_remote_seeker_node() -> Node:
	var scene = preload("res://common/game/player/seeker/RemoteSeeker.tscn")
	return scene.instance()


func create_remote_hider_node() -> Node:
	var scene = preload("res://common/game/player/hider/RemoteHider.tscn")
	return scene.instance()


####################################
# create_player_xxx_node()
# These methods are used for creating players who are not
# localy controlled by this machine.
func create_player_seeker_node() -> Node:
	print("create_player_seeker_node() MUST BE OVERRIDEN")
	assert(false)
	return null	


func create_player_hider_node() -> Node:
	print("create_player_hider_node() MUST BE OVERRIDEN")
	assert(false)
	return null	
