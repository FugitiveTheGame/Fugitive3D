extends GdUnitTestSuite

# A bot fugitive dropped into a real server game has to get itself off the
# spawn and across the map toward the safe zone under its own power. This
# runs the actual server game scene on Littleton with one human cop standing
# still and one bot, then lets physics run.

const SERVER_GAME := "res://server/game/mode/fugitive/ServerFugitiveGame.tscn"
const LITTLETON := "littleton"
const HUMAN_COP_ID := 42
const SERVER_PORT := 31993
const TIME_SCALE := 4.0
# Well short of the safe zone, so the round cannot end and pull the server
# back to the lobby scene mid-test
const HEADSTART_SECONDS := 8.0
const MIN_PROGRESS := 20.0

var game: ServerFugitiveGame


func before_test() -> void:
	# A dedicated server always has a live ENet peer behind its RPCs
	assert_bool(ServerNetwork.host_game(SERVER_PORT)).is_true()
	GameData.general[GameData.GENERAL_MAP] = LITTLETON
	GameData.general[GameData.GENERAL_SEED] = 1234

	var cop := GameData.create_new_player_raw_data(HUMAN_COP_ID, PlatformTypeUtils.PlatformType.FlatDesktop, "Cop", FugitiveTeamResolver.PlayerType.Seeker)
	GameData.add_player_from_raw_data(cop)
	ServerNetwork.nextBotId = ServerNetwork.BOT_ID_BASE
	ServerNetwork.on_add_bot()

	game = (load(SERVER_GAME) as PackedScene).instantiate()
	add_child(game)
	# The game configures itself over two deferred calls after _ready
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	# Stand in for the human client reporting configured and ready
	game.on_all_clients_configured()
	game.stateMachine.transition_by_name(FugitiveStateMachine.TRANS_READY)
	game.on_all_ready()
	game.map.get_countdown_timer().stop()
	game.begin_game()


func after_test() -> void:
	Engine.time_scale = 1.0
	if is_instance_valid(game):
		game.queue_free()
		await get_tree().process_frame
	ClientNetwork.reset_network()


func _bot() -> AiHiderController:
	var botId: int = GameData.get_bot_player_ids()[0]
	return game.get_player(botId).playerController as AiHiderController


func _safe_zone() -> Vector3:
	return game.map.get_win_zones()[0].global_transform.origin


func _simulate(seconds: float) -> void:
	Engine.time_scale = TIME_SCALE
	var frames := int(seconds * Engine.physics_ticks_per_second / TIME_SCALE)
	for frame in frames:
		await get_tree().physics_frame
	Engine.time_scale = 1.0


func test_the_bot_is_a_server_driven_hider() -> void:
	var bot := _bot()
	assert_object(bot).is_not_null()
	assert_bool(bot.player.is_in_group(Hider.GROUP)).is_true()
	assert_int(bot.get_multiplayer_authority()).is_equal(ServerNetwork.SERVER_ID)
	assert_str(game.current_state()).is_equal(FugitiveStateMachine.STATE_PLAYING_HEADSTART)


func test_the_bot_heads_for_the_safe_zone_during_the_headstart() -> void:
	var bot := _bot()
	var start: Vector3 = bot.global_transform.origin
	var start_distance := start.distance_to(_safe_zone())

	await _simulate(HEADSTART_SECONDS)

	var end: Vector3 = bot.global_transform.origin
	assert_bool(bot.player.frozen).is_false()
	assert_float(end.distance_to(start)).override_failure_message(
		"Bot never left the spawn: %s -> %s" % [start, end]).is_greater(MIN_PROGRESS)
	assert_float(end.distance_to(_safe_zone())).override_failure_message(
		"Bot did not close on the safe zone: %.1f -> %.1f" % [start_distance, end.distance_to(_safe_zone())]).is_less(start_distance - MIN_PROGRESS)


func test_the_bot_stays_on_the_ground() -> void:
	var bot := _bot()
	await _simulate(HEADSTART_SECONDS)
	assert_float(bot.global_transform.origin.y).is_between(-1.0, 1.5)


# A cop released a short way down the bot's route is close enough to see, so
# the bot has to stop advancing and go to ground
func test_the_bot_hides_from_a_cop_in_view() -> void:
	var bot := _bot()
	var brain: AiHiderBrain = bot.get_node("Brain")
	await _simulate(2.0)

	var cop: FugitivePlayer = game.get_player(HUMAN_COP_ID)
	var ahead: Vector3 = bot.global_transform.origin + (_safe_zone() - bot.global_transform.origin).normalized() * 10.0
	var grid: FugitiveNavGrid = game.get_nav_grid(bot.get_world_3d().direct_space_state)
	var cell := grid.nearest_walkable(grid.world_to_cell(ahead))
	cop.playerController.global_transform.origin = grid.cell_to_world(cell, 0.5)
	game.release_cops()

	await _simulate(3.0)

	assert_bool(cop.frozen).is_false()
	assert_bool(brain.mode in [AiHiderBrain.Mode.HIDE, AiHiderBrain.Mode.FLEE]).override_failure_message(
		"Bot kept going in mode %s with a cop %.1fm away" % [AiHiderBrain.Mode.keys()[brain.mode], bot.global_transform.origin.distance_to(cop.playerController.global_transform.origin)]).is_true()
	assert_bool(bot.want_sprint and brain.mode == AiHiderBrain.Mode.HIDE).is_false()
