extends FugitiveGame
class_name ServerFugitiveGame

onready var advertiser := $ServerAdvertiser as ServerAdvertiser

var configuredPlayers := {}
var readyPlayers := {}


func _enter_tree():
	ClientNetwork.connect("remove_player", self, "server_remove_player")


func _exit_tree():
	ClientNetwork.disconnect("remove_player", self, "server_remove_player")


func _ready():
	if ServerUtils.get_fps():
		$FpsTimer.start()
	
	ServerUtils.normal_start(advertiser, false)


func pre_configure():
	.pre_configure()
	
	print("Server configuration complete")


func unconfigured_players() -> int:
	var count := 0
	for playerId in GameData.players:
		if not configuredPlayers.has(playerId):
			count += 1
	
	return count


func not_ready_players() -> int:
	var count := 0
	for playerId in GameData.players:
		if not readyPlayers.has(playerId):
			count += 1
	
	return count


func server_remove_player(playerId: int):
	# If all players are gone, return to lobby
	if GameData.players.empty():
		print("All players disconnected, returning to lobby")
		get_tree().change_scene("res://server/lobby/ServerLobby.tscn")
	else:
		print("Players remaining: %d" % GameData.players.size())
		
		if stateMachine.current_state.name == FugitiveStateMachine.STATE_CONFIGURING:
			check_all_configured()
		elif stateMachine.current_state.name == FugitiveStateMachine.STATE_NOT_READY:
			check_all_ready()


func load_map():
	.load_map()
	map.get_countdown_timer().connect("timeout", self, "countdown_timer_timeout")
	map.get_headstart_timer().connect("timeout", self, "headstart_timer_timeout")


remote func on_client_configured(playerId: int):
	print("client configured: %s" % playerId)
	configuredPlayers[playerId] = true
	
	check_all_configured()


func check_all_configured():
	# All clients are done, unpause the game
	if unconfigured_players() == 0:
		if current_state() == FugitiveStateMachine.STATE_CONFIGURING:
			print("All players report configured.")
			rpc("on_all_clients_configured")
		else:
			print("Discarding client configuration status, everyone is already past configuration")
	else:
		print("Still waiting on %d players" % unconfigured_players())


remote func on_client_ready(playerId: int):
	print("client ready: %s" % playerId)
	readyPlayers[playerId] = true
	
	check_all_ready()


func check_all_ready():
	if not_ready_players() > 0:
		print("Still waiting on %d players" % not_ready_players())
	# All clients are done, unpause the game
	else:
		stateMachine.transition_by_name(FugitiveStateMachine.TRANS_READY)
		print("Starting the countdown")
		rpc("on_all_ready")


# Only the Server listens to the timer
func countdown_timer_timeout():
	print("Start timer expired")
	rpc("begin_game")


func headstart_timer_timeout():
	print("Headstart timer expired")
	rpc("release_cops")


# Only the server will call this as it sends all clients back to lobby
func send_all_to_lobby():
	if get_tree().is_network_server():
		rpc("on_go_to_lobby")


remotesync func on_go_to_lobby():
	print("SERVER: on_go_to_lobby()")
	get_tree().change_scene("res://server/lobby/ServerLobby.tscn")


func _on_FpsTimer_timeout():
	print("%d fps" % Engine.get_frames_per_second())


func finish_game(playerType: int):
	.finish_game(playerType)
	
	##########################
	# Calculate end-game stats
	##########################
	var hiders = get_tree().get_nodes_in_group(Hider.GROUP)
	var winZones := map.get_win_zones()
	
	for hider in hiders:
		if not hider.frozen:
			for winZone in winZones:
				# If a hider is unfrozen and in any win zone, give them an "escaped" counter.
				if (winZone.overlaps_body(hider.playerBody)):					
					FugitivePlayerDataUtility.increment_stat_for_player_id(hider.id, FugitivePlayerDataUtility.STAT_HIDER_ESCAPED)
					break
	
	for player in GameData.get_players():
		var playerId = player.get_id()
		# All players get credit for playing the game
		FugitivePlayerDataUtility.increment_stat_for_player_id(playerId, FugitivePlayerDataUtility.STAT_GAMES)
		
		# If this player was on the winning team, give them a win
		if player.get_type() == playerType:
			FugitivePlayerDataUtility.increment_stat_for_player_id(playerId, FugitivePlayerDataUtility.STAT_WINS)
	
	rpc("on_finish_game", playerType)


func _on_StateMachine_state_change(new_state, transition):
	print("new state: %s via: %s" % [new_state.name, transition.name])


func on_state_game_over(current_state: State, transition: Transition):
	.on_state_game_over(current_state, transition)
	print("Server returning to lobby")
	go_to_lobby()
