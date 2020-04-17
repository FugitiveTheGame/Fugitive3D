extends GameMode
class_name FugitiveGame

onready var stateMachine := $StateMachine as FugitiveStateMachine

var mapPath: String = "res://common/game/maps/test_map_01/TestMap01.scn"
var map: FugitiveMap
var players: Node
var gameTimer: Timer
var localPlayer: Player

var gameStarted := false
var gameOver := false


func _ready():
	print("Entering game")
	get_tree().paused = true
	
	load_map()
	
	ClientNetwork.connect("remove_player", self, "remove_player")
	
	pre_configure()


func load_map():
	var scene := load(mapPath)
	map = scene.instance()
	add_child(map)
	players = map.get_players()
	gameTimer = map.get_game_timer()
	gameTimer.connect("timeout", self, "game_time_limit_exceeded")


# If a player has disconnected, remove them from the world
func remove_player(playerId: int):
	var playerNode = players.get_node(str(playerId))
	playerNode.queue_free()


################################
# This is called by the GameMode class when it has decided
# the game is complete

# This will be overriden by ServerGame.
# The server will trigger the actual end-game functionality
# This makes the server authoratative about when the game ends
func finish_game():
	rpc("on_finish_game")


remotesync func on_finish_game():
	var curState := stateMachine.current_state.name
	
	# There are only 2 valid states that the game can be finished from
	if curState == FugitiveStateMachine.STATE_PLAYING_HEADSTART:
		stateMachine.transition_by_name(FugitiveStateMachine.TRANS_END_GAME_EARLY)
	elif curState == FugitiveStateMachine.STATE_PLAYING:
		stateMachine.transition_by_name(FugitiveStateMachine.TRANS_END_GAME)
	else:
		print("FATAL! on_finish_game(): cannot finish game, in invalid state: %s " % curState)
		assert(false)

################################
# Pre-game configuration
# Create all of the players and entities
# This has to be completed on all clients before the game can start
# Once completed, notify the server that we are done
func pre_configure():
	var sortedPlayers = []
	for playerId in GameData.players:
		sortedPlayers.push_back(playerId)
	
	sortedPlayers.sort()
	
	var hiderSpawns = map.get_hider_spawns()
	assert(not hiderSpawns.empty())
	
	var seekerSpawns = map.get_seeker_spawns()
	assert(not seekerSpawns.empty())
	
	for playerId in sortedPlayers:
		spawn_player(playerId, hiderSpawns, seekerSpawns)


# Spawn an individual player for the local client
func spawn_player(playerId: int, hiderSpawns: Array, seekerSpawns: Array):
	print("Creating player game object")
	
	# Extract the player data
	var player = GameData.players[playerId]
	var playerName := player[GameData.PLAYER_NAME] as String
	var playerType := player[GameData.PLAYER_TYPE] as int
	
	# This is the node for the PlayerController
	var pcNode: Node
	var spawnPointNode: Spatial
	var spawnPoint: Vector3
	
	# Create the player controller for the local player
	if get_tree().get_network_unique_id() == playerId:
		match playerType:
			GameData.PlayerType.Seeker:
				pcNode = create_player_seeker_node()
				spawnPointNode = seekerSpawns.pop_front()
			GameData.PlayerType.Hider:
				pcNode = create_player_hider_node()
				spawnPointNode = hiderSpawns.pop_front()
	# Create the player controller for all remote players
	else:
		match playerType:
			GameData.PlayerType.Seeker:
				pcNode = create_remote_seeker_node()
				spawnPointNode = seekerSpawns.pop_front()
			GameData.PlayerType.Hider:
				pcNode = create_remote_hider_node()
				spawnPointNode = hiderSpawns.pop_front()
	
	pcNode.set_network_master(playerId)
	pcNode.set_name(str(playerId))
	
	# Final setup and config for the player
	var playerNode = pcNode.get_node("Player")
	playerNode.configure(playerName)
	# Player listens to Game state changes
	stateMachine.connect("state_change", playerNode, "on_game_state_changed")
	
	# Add the PlayerController to the player's node in the game scene
	players.add_child(pcNode)
	
	# Move to the spawn point
	pcNode.global_transform.origin = spawnPointNode.global_transform.origin
	pcNode.global_transform.basis = spawnPointNode.global_transform.basis


remotesync func on_all_clients_configured():
	print("All clients are configured. Waiting for them to ready up.")
	get_tree().paused = false
	stateMachine.transition_by_name(FugitiveStateMachine.TRANS_CONFIGURED)


# When all clients have reported that they have finished setting up the gmae
# The server calls this on all clients telling them to start the game
remotesync func on_all_ready():
	print("All clients are ready. Starting the count down.")
	stateMachine.transition_by_name(FugitiveStateMachine.TRANS_START_COUNT)


####################################
# create_remote_xxx_node()
# These methods are used for creating players who are not
# localy controlled by this machine.
func create_remote_seeker_node() -> Node:
	var scene = preload("res://common/game/mode/fugitive/seeker/RemoteSeeker.tscn")
	return scene.instance()


func create_remote_hider_node() -> Node:
	var scene = preload("res://common/game/mode/fugitive/hider/RemoteHider.tscn")
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

###################################


func _process(delta):
	if gameStarted and not gameOver:
		process_hiders()
		check_win_conditions()


func process_hiders():
	var seekers = get_tree().get_nodes_in_group(Seeker.GROUP)
	var hiders = get_tree().get_nodes_in_group(Hider.GROUP)
	var lights = get_tree().get_nodes_in_group(Groups.LIGHTS)
	
	var curPlayerType = GameData.get_current_player_type()
	
	# Process each hider, find if any have been seen
	for hider in hiders:
		# Re-hide Hiders every frame
		if not hider.frozen:
			hider.current_visibility = 0.0
		# Frozen Hiders should always be vizible to Seekers
		else:
			hider.current_visibility = 1.0
			
		# If the hider is moving at all, make them a little visible
		# regaurdless of FOV/Distance
		var percent_visible = hider.current_visibility
		if hider.is_moving_fast():
			percent_visible += Seeker.SPRINT_VISIBILITY_PENALTY
		elif hider.is_moving():
			percent_visible += Seeker.MOVEMENT_VISIBILITY_PENALTY
		
		hider.current_visibility = clamp(percent_visible, 0.0, 1.0)
		
		for seeker in seekers:
			seeker.process_hider(hider)
		
		for light in lights:
			light.process_hider(hider)


func check_win_conditions():
	# Only the server will end the game
	if not get_tree().is_network_server():
		return
	
	var hiders = get_tree().get_nodes_in_group(Hider.GROUP)
	var seekers = get_tree().get_nodes_in_group(Seeker.GROUP)
	var winZones := map.get_win_zones()
	
	# We are debugging if there is exactly 1 player
	var isDebugging = (hiders.empty() and seekers.size() == 1) or (seekers.empty() and hiders.size() == 1)
	
	# Normal win condition:
	# Either all hiders are frozen OR
	# all non-frozen hiders are in a winzone
	if not isDebugging:
		var allHidersFrozen := true
		var allUnfrozenSeekersInWinZone := true
	
		for hider in hiders:
			if (not hider.frozen):
				allHidersFrozen = false
				for winZone in winZones:
					# Now, check if this hider is in the win zone.
					if (not winZone.overlaps_body(hider.playerBody)):
						allUnfrozenSeekersInWinZone = false
		
		if gameStarted and (allHidersFrozen or allUnfrozenSeekersInWinZone):
			finish_game()
	# Debug win condition:
	# The only player enteres any win zone
	else:
		var player
		if not hiders.empty():
			player = hiders[0]
		else:
			player = seekers[0]
		
		var body = player.playerBody
		for winZone in winZones:
			# Now, check if this hider is in the win zone.
			if winZone.overlaps_body(body):
				finish_game()
				break


func game_time_limit_exceeded():
	print("Time ran out!")
	finish_game()


func on_state_countdown(current_state: State, transition: Transition):
	print("Starting countdown")
	map.get_start_timer().start()


remotesync func begin_game():
	print("Release the hiders!")
	stateMachine.transition_by_name(FugitiveStateMachine.TRANS_GAME_START)
	map.get_headstart_timer().start()
	gameTimer.start()
	gameStarted = true


remotesync func release_cops():
	print("Release the cops!")
	stateMachine.transition_by_name(FugitiveStateMachine.TRANS_COPS_RELEASED)


func on_state_end_game():
	self.gameOver = true
	print("game is complete!")
