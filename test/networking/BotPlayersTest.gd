extends GdUnitTestSuite

# Bots are lobby players the server owns outright: no peer, always ready, and
# pinned to the Fugitive team. Everything that fans an RPC out over the player
# list has to know they are not somewhere it can send to.

const HUMAN_ID := 42
const SERVER_PORT := 31994
const LITTLETON := "littleton"


func before_test() -> void:
	# A dedicated server always has a live ENet peer behind its RPCs
	assert_bool(ServerNetwork.host_game(SERVER_PORT)).is_true()
	GameData.general[GameData.GENERAL_MAP] = LITTLETON
	ServerNetwork.nextBotId = ServerNetwork.BOT_ID_BASE


func after_test() -> void:
	GameData.currentGame = null
	ClientNetwork.reset_network()


func _add_human(playerId: int) -> void:
	var raw := GameData.create_new_player_raw_data(playerId, PlatformTypeUtils.PlatformType.FlatDesktop, "Human %d" % playerId, FugitiveTeamResolver.PlayerType.Seeker)
	GameData.add_player_from_raw_data(raw)


func test_new_players_are_not_bots_by_default() -> void:
	_add_human(HUMAN_ID)
	assert_bool(GameData.get_player(HUMAN_ID).get_is_bot()).is_false()
	assert_bool(GameData.is_bot(HUMAN_ID)).is_false()


func test_add_bot_registers_a_ready_fugitive() -> void:
	ServerNetwork.on_add_bot()

	var bots := GameData.get_bot_player_ids()
	assert_int(bots.size()).is_equal(1)

	var bot := GameData.get_player(bots[0])
	assert_bool(bot.get_is_bot()).is_true()
	assert_bool(bot.get_lobby_ready()).is_true()
	assert_int(bot.get_type()).is_equal(FugitiveTeamResolver.PlayerType.Hider)
	assert_int(bot.get_platform_type()).is_equal(PlatformTypeUtils.PlatformType.Bot)
	assert_str(bot.get_name()).is_not_empty()


func test_bots_get_distinct_ids_above_the_peer_range() -> void:
	ServerNetwork.on_add_bot()
	ServerNetwork.on_add_bot()

	var bots := GameData.get_bot_player_ids()
	assert_int(bots.size()).is_equal(2)
	assert_int(bots[0]).is_not_equal(bots[1])
	for botId in bots:
		assert_int(botId).is_greater_equal(ServerNetwork.BOT_ID_BASE)


# Peer ids are random, so the bot range is no guarantee on its own
func test_a_bot_never_takes_an_id_already_in_use() -> void:
	_add_human(ServerNetwork.BOT_ID_BASE)
	ServerNetwork.on_add_bot()

	var bots := GameData.get_bot_player_ids()
	assert_int(bots.size()).is_equal(1)
	assert_int(bots[0]).is_not_equal(ServerNetwork.BOT_ID_BASE)
	assert_bool(GameData.get_player(ServerNetwork.BOT_ID_BASE).get_is_bot()).is_false()


func test_a_peer_whose_id_collides_with_a_bot_is_sent_away() -> void:
	ServerNetwork.on_add_bot()
	var botId: int = GameData.get_bot_player_ids()[0]

	ServerNetwork.on_register_self(botId, PlatformTypeUtils.PlatformType.FlatDesktop, "Unlucky", UserData.GAME_VERSION)

	assert_int(GameData.players.size()).is_equal(1)
	assert_bool(GameData.get_player(botId).get_is_bot()).is_true()
	assert_str(GameData.get_player(botId).get_name()).is_equal("AI Fugitive 1")


func test_humans_and_bots_are_listed_apart() -> void:
	_add_human(HUMAN_ID)
	ServerNetwork.on_add_bot()

	assert_array(GameData.get_human_player_ids()).contains_exactly([HUMAN_ID])
	assert_int(GameData.get_bot_player_ids().size()).is_equal(1)


func test_cannot_add_more_bots_than_the_map_allows() -> void:
	var maxHiders: int = Maps.get_team_sizes_for_map(LITTLETON)[FugitiveTeamResolver.PlayerType.Hider]
	for ii in maxHiders + 3:
		ServerNetwork.on_add_bot()

	assert_int(GameData.get_bot_player_ids().size()).is_equal(maxHiders)
	assert_bool(ServerNetwork.can_add_bot()).is_false()


func test_cannot_add_bots_during_a_game() -> void:
	GameData.currentGame = GameMode.new()
	auto_free(GameData.currentGame)

	assert_bool(ServerNetwork.can_add_bot()).is_false()
	ServerNetwork.on_add_bot()
	assert_int(GameData.get_bot_player_ids().size()).is_equal(0)


func test_kicking_a_bot_removes_it() -> void:
	ServerNetwork.on_add_bot()
	var botId: int = GameData.get_bot_player_ids()[0]

	ServerNetwork.on_kick_player(botId)

	assert_bool(GameData.players.has(botId)).is_false()


func test_bots_never_change_team() -> void:
	ServerNetwork.on_add_bot()
	var botId: int = GameData.get_bot_player_ids()[0]

	ServerNetwork.on_change_player_type(botId, FugitiveTeamResolver.PlayerType.Seeker)

	assert_int(GameData.get_player(botId).get_type()).is_equal(FugitiveTeamResolver.PlayerType.Hider)


func test_bots_never_become_host() -> void:
	ServerNetwork.on_add_bot()
	var botId: int = GameData.get_bot_player_ids()[0]

	ServerNetwork.make_host(botId)

	assert_object(GameData.get_host()).is_null()


# The first player to join is host, and the host is the server's admin: the
# only peer allowed to add, remove or kick
func test_only_the_host_may_manage_bots() -> void:
	_add_human(HUMAN_ID)
	_add_human(HUMAN_ID + 1)
	ServerNetwork.make_host(HUMAN_ID)

	assert_bool(ServerNetwork.is_host_or_server(HUMAN_ID)).is_true()
	assert_bool(ServerNetwork.is_host_or_server(HUMAN_ID + 1)).is_false()
	assert_bool(ServerNetwork.is_host_or_server(ServerNetwork.SERVER_ID)).is_true()
	assert_bool(ServerNetwork.is_host_or_server(0)).is_true()


func test_nobody_manages_bots_while_there_is_no_host() -> void:
	_add_human(HUMAN_ID)
	assert_bool(ServerNetwork.is_host_or_server(HUMAN_ID)).is_false()


func test_host_passes_to_a_human_not_a_bot() -> void:
	ServerNetwork.on_add_bot()
	_add_human(HUMAN_ID)
	_add_human(HUMAN_ID + 1)
	ServerNetwork.make_host(HUMAN_ID)

	GameData.remove_player(HUMAN_ID)
	ServerNetwork._player_disconnected(HUMAN_ID)

	assert_int(GameData.get_host().get_id()).is_equal(HUMAN_ID + 1)


func test_bots_leave_with_the_last_human() -> void:
	_add_human(HUMAN_ID)
	ServerNetwork.on_add_bot()
	ServerNetwork.on_add_bot()

	GameData.remove_player(HUMAN_ID)
	ServerNetwork._player_disconnected(HUMAN_ID)

	assert_bool(GameData.players.is_empty()).is_true()


# The base handler that drops the leaver from the player list runs first only
# by connection order, so the leaver must not count as a remaining human
func test_bots_leave_even_if_the_leaver_is_still_listed() -> void:
	_add_human(HUMAN_ID)
	ServerNetwork.on_add_bot()

	ServerNetwork._player_disconnected(HUMAN_ID)

	assert_array(GameData.get_bot_player_ids()).is_empty()


func test_bots_stay_while_another_human_remains() -> void:
	_add_human(HUMAN_ID)
	_add_human(HUMAN_ID + 1)
	ServerNetwork.on_add_bot()

	GameData.remove_player(HUMAN_ID)
	ServerNetwork._player_disconnected(HUMAN_ID)

	assert_int(GameData.get_bot_player_ids().size()).is_equal(1)


func test_starting_a_game_leaves_bots_ready() -> void:
	_add_human(HUMAN_ID)
	ServerNetwork.on_add_bot()
	var botId: int = GameData.get_bot_player_ids()[0]

	ClientNetwork.on_start_game()

	assert_bool(GameData.get_player(HUMAN_ID).get_lobby_ready()).is_false()
	assert_bool(GameData.get_player(botId).get_lobby_ready()).is_true()


func test_randomizing_teams_leaves_bots_as_fugitives() -> void:
	_add_human(HUMAN_ID)
	_add_human(HUMAN_ID + 1)
	_add_human(HUMAN_ID + 2)
	ServerNetwork.on_add_bot()
	var botId: int = GameData.get_bot_player_ids()[0]

	for attempt in 5:
		ServerNetwork.on_randomize_teams()
		assert_int(GameData.get_player(botId).get_type()).is_equal(FugitiveTeamResolver.PlayerType.Hider)


# Bots already fill Fugitive slots, so a shuffle must hand the humans only
# what is left under the map's cap or the lobby can no longer start
func test_randomizing_teams_respects_the_fugitive_cap_with_bots() -> void:
	var maxHiders: int = Maps.get_team_sizes_for_map(LITTLETON)[FugitiveTeamResolver.PlayerType.Hider]
	for ii in 4:
		_add_human(HUMAN_ID + ii)
	for ii in maxHiders - 1:
		ServerNetwork.on_add_bot()

	for attempt in 5:
		ServerNetwork.on_randomize_teams()
		assert_int(GameData.count_players_of_type(FugitiveTeamResolver.PlayerType.Hider)).is_less_equal(maxHiders)
		assert_int(GameData.count_players_of_type(FugitiveTeamResolver.PlayerType.Hider)).is_greater_equal(maxHiders - 1)
