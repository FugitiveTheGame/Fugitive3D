extends ClientFugitiveGame

# Change this to determine what you will spwan as
var be_seeker := true


func _enter_tree():
	GameData.general[GameData.GENERAL_MAP] = 4
	
	GameData.currentGame = self
	
	GameAnalytics.DEVELOPMENT = true
	
	# Silence the start sound
	(GameData.currentGame.get_node("StartAudio") as AudioStreamPlayer).volume_db = -100.0
	(GameData.currentGame.get_node("PregameCountdownAudio") as AudioStreamPlayer).volume_db = -100.0
	
	# Start a local server, the whole game expects to be multiplayer	
	var peer := NetworkedMultiplayerENet.new()
	var _result := peer.create_server(5555, 5)
	ServerNetwork.is_joinable = false
	get_tree().set_network_peer(peer)
	
	# Add our fake players, the normal spawn system will actually spawn these guys
	if be_seeker:
		GameData.add_player_from_raw_data(GameData.create_new_player_raw_data(1, PlatformTypeUtils.PlatformType.FlatDesktop, "real player", FugitiveTeamResolver.PlayerType.Seeker))
	else:
		GameData.add_player_from_raw_data(GameData.create_new_player_raw_data(1, PlatformTypeUtils.PlatformType.FlatDesktop, "real player", FugitiveTeamResolver.PlayerType.Hider))

	var numHiders := 8
	for ii in numHiders:
		GameData.add_player_from_raw_data(GameData.create_new_player_raw_data(100 + ii, PlatformTypeUtils.PlatformType.FlatDesktop, "dumb donkey H%d" % ii, FugitiveTeamResolver.PlayerType.Hider))
	
	var numSeekers := 0
	for ii in numSeekers:
		GameData.add_player_from_raw_data(GameData.create_new_player_raw_data(200 + ii, PlatformTypeUtils.PlatformType.FlatDesktop, "dumb donkey S%d" % ii, FugitiveTeamResolver.PlayerType.Seeker))


func _ready():
	# Shorten up the wait times so we can test right away
	map.get_countdown_timer().wait_time = 0.25
	map.get_headstart_timer().wait_time = 0.25
	
	# Normally the server listens to these
	map.get_countdown_timer().connect("timeout", self, "start_timer_timeout")
	map.get_headstart_timer().connect("timeout", self, "headstart_timer_timeout")
	
	# Unlock all cars for the hider
	if not be_seeker:
		var cars = get_tree().get_nodes_in_group(Groups.CARS)
		for car in cars:
			car.locked = false
	
	# Artificially ready the client
	call_deferred("explore_ready")


func explore_ready():
	# Ready the local client
	stateMachine.transition_by_name(FugitiveStateMachine.TRANS_READY)
	
	# Norally the server would call this after all clients have submitted ready
	call_deferred("on_all_ready")


# Emulating what the server would normmally do here
func start_timer_timeout():
	begin_game()


# Emulating what the server would normmally do here
func headstart_timer_timeout():
	release_cops()


# Emulating what the server would normmally do here
func finish_game(playerType: int):
	on_finish_game(playerType)
