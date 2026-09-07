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
const MIN_PROGRESS := 15.0

var game: ServerFugitiveGame


func before_test() -> void:
	# A dedicated server always has a live ENet peer behind its RPCs
	assert_bool(ServerNetwork.host_game(SERVER_PORT)).is_true()
	GameData.general[GameData.GENERAL_MAP] = LITTLETON
	GameData.general[GameData.GENERAL_SEED] = 1234

	var cop := GameData.create_new_player_raw_data(HUMAN_COP_ID, PlatformTypeUtils.PlatformType.FlatDesktop, "Cop", FugitiveTeamResolver.PlayerType.Seeker)
	GameData.add_player_from_raw_data(cop)
	ServerNetwork.nextBotId = ServerNetwork.BOT_ID_BASE
	# Three bots: tests drive the first two, the third stays back near spawn
	# so every hider can never be in the safe zone at once, which would end
	# the round and send the server scene back to the lobby mid-test. One of
	# each difficulty, hardest first, so the driven bots are the direct ones.
	ServerNetwork.on_add_bot(AiDifficulty.Level.HARD)
	ServerNetwork.on_add_bot(AiDifficulty.Level.MEDIUM)
	ServerNetwork.on_add_bot(AiDifficulty.Level.EASY)

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


func _bot(index := 0) -> AiHiderController:
	var ids := GameData.get_bot_player_ids()
	ids.sort()
	return game.get_player(ids[index]).playerController as AiHiderController


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


# The safe zone box is narrow on the side bots arrive from. The first one in
# must not stop in the doorway and block the second, and a cop breathing down
# their necks must not talk either of them out of the last few metres
func test_both_bots_get_into_the_safe_zone_past_a_cop() -> void:
	var first := _bot(0)
	var second := _bot(1)
	var grid: FugitiveNavGrid = game.get_nav_grid(first.get_world_3d().direct_space_state)

	# Line both up on the final stretch of the real approach, one behind the
	# other, with the cop in plain view beside the zone. The approach is a
	# single cell wide, so a cop standing in it would make the zone
	# unreachable rather than merely dangerous.
	var route := grid.find_path(first.global_transform.origin, _safe_zone())
	assert_int(route.size()).is_greater(8)
	first.global_transform.origin = route[route.size() - 5] + Vector3(0.0, 0.5, 0.0)
	second.global_transform.origin = route[route.size() - 7] + Vector3(0.0, 0.5, 0.0)
	var cop: FugitivePlayer = game.get_player(HUMAN_COP_ID)
	var beside_zone := grid.nearest_walkable(grid.world_to_cell(_safe_zone() + Vector3(0.0, 0.0, -6.0)))
	cop.playerController.global_transform.origin = grid.cell_to_world(beside_zone, 0.5)
	game.release_cops()

	await _simulate(8.0)

	assert_bool(first.player.is_in_winzone()).override_failure_message(
		"First bot ended outside the zone at %s" % first.global_transform.origin).is_true()
	assert_bool(second.player.is_in_winzone()).override_failure_message(
		"Second bot ended outside the zone at %s" % second.global_transform.origin).is_true()
	# Both head for the centre and stop against each other there
	assert_float(first.global_transform.origin.distance_to(_safe_zone())).is_less(2.0)
	assert_float(second.global_transform.origin.distance_to(_safe_zone())).is_less(2.0)
	assert_str(game.current_state()).is_equal(FugitiveStateMachine.STATE_PLAYING)


# A cop released a short way down the bot's route is close enough to see, so
# the bot has to stop advancing and go to ground
func test_the_bot_hides_from_a_cop_in_view() -> void:
	var bot := _bot()
	var brain: AiHiderBrain = bot.get_node("Brain")
	await _simulate(2.0)

	# The cop stands a few cells along the route the bot is actually walking,
	# so it is in plain view whichever way the road bends
	var cop: FugitivePlayer = game.get_player(HUMAN_COP_ID)
	var grid: FugitiveNavGrid = game.get_nav_grid(bot.get_world_3d().direct_space_state)
	var route := grid.find_path(bot.global_transform.origin, _safe_zone())
	assert_int(route.size()).is_greater(4)
	cop.playerController.global_transform.origin = route[3] + Vector3(0.0, 0.5, 0.0)
	game.release_cops()

	# A bot that runs far enough is out of range again and free to carry on,
	# so what matters is that it went to ground at some point, not where it
	# stands at the end
	var went_to_ground := false
	var sprinted_while_hiding := false
	for step in 12:
		await _simulate(0.25)
		if brain.mode in [AiHiderBrain.Mode.HIDE, AiHiderBrain.Mode.FLEE]:
			went_to_ground = true
		if bot.want_sprint and brain.mode == AiHiderBrain.Mode.HIDE:
			sprinted_while_hiding = true

	assert_bool(cop.frozen).is_false()
	assert_bool(went_to_ground).override_failure_message(
		"Bot kept going in mode %s with a cop %.1fm away" % [AiHiderBrain.Mode.keys()[brain.mode], bot.global_transform.origin.distance_to(cop.playerController.global_transform.origin)]).is_true()
	assert_bool(sprinted_while_hiding).is_false()


# The difficulty chosen in the lobby reaches the body and the brain that
# spawned for it
func test_difficulty_sets_the_pace_and_the_nerve() -> void:
	await _simulate(0.5)
	var hard := _bot(0)
	var easy := _bot(2)
	var hard_brain: AiHiderBrain = hard.get_node("Brain")
	var easy_brain: AiHiderBrain = easy.get_node("Brain")

	assert_float(hard.player.speed_scale).is_equal(AiDifficulty.profile(AiDifficulty.Level.HARD).speed_scale)
	assert_float(easy.player.speed_scale).is_equal(AiDifficulty.profile(AiDifficulty.Level.EASY).speed_scale)
	assert_float(hard.player.max_speed()).is_greater(easy.player.max_speed())
	assert_float(hard_brain.profile.see_distance).is_greater(easy_brain.profile.see_distance)
	assert_float(hard_brain.profile.caution_distance).is_greater(easy_brain.profile.caution_distance)
	# The body and the brain read the same profile
	assert_object(hard_brain.profile).is_same(hard.profile)


# An easy bot wanders on its way in, and every wander has to end with it
# back on the road to the safe zone rather than stood still somewhere
func test_an_easy_bot_wanders_but_keeps_going() -> void:
	var bot := _bot(2)
	var brain: AiHiderBrain = bot.get_node("Brain")
	await _simulate(0.5)
	brain.profile.detour_chance = 1.0

	# Wandering can bring it back past where it started, so the measure is
	# how far it walked, not how far it got
	var travelled := 0.0
	var last: Vector3 = bot.global_transform.origin
	for step in 16:
		await _simulate(HEADSTART_SECONDS / 16.0)
		travelled += bot.global_transform.origin.distance_to(last)
		last = bot.global_transform.origin

	assert_bool(bot.player.frozen).is_false()
	assert_float(last.y).is_between(-1.0, 1.5)
	assert_float(travelled).override_failure_message(
		"Easy bot barely moved, %.1fm in %.0fs" % [travelled, HEADSTART_SECONDS]).is_greater(MIN_PROGRESS)
	assert_int(brain.mode).is_equal(AiHiderBrain.Mode.ADVANCE)
	assert_bool(bot.has_target).is_true()


# A detour the grid cannot route to is dropped rather than held on to
func test_a_detour_with_no_route_is_dropped() -> void:
	var bot := _bot(1)
	var brain: AiHiderBrain = bot.get_node("Brain")
	await _simulate(0.5)
	var start: Vector3 = bot.global_transform.origin
	var nowhere := Vector3(1000.0, 0.0, 1000.0)
	brain.detour_goal = nowhere

	await _simulate(3.0)

	# By now the bot may well have rolled a fresh, reachable detour
	assert_bool(brain.detour_goal == null or brain.detour_goal != nowhere).override_failure_message(
		"Bot is still holding on to a detour it cannot reach").is_true()
	assert_bool(bot.has_target).is_true()
	assert_float(bot.global_transform.origin.distance_to(start)).override_failure_message(
		"Bot stood still on a dead detour at %s" % start).is_greater(3.0)
