extends GdUnitTestSuite

# The host adds AI fugitives from the lobby. They show up in the player list
# like anyone else, but pinned to their team and marked as bots.

const FLAT_LOBBY := "res://client/lobby/flat/FlatLobby.tscn"
const VR_LOBBY_UI := "res://client/lobby/vr/VrLobbyUi.tscn"
const SERVER_PORT := 31995
const LITTLETON := "littleton"

var lobby: Lobby


func before_test() -> void:
	assert_bool(ServerNetwork.host_game(SERVER_PORT)).is_true()
	GameData.general[GameData.GENERAL_MAP] = LITTLETON
	ServerNetwork.nextBotId = ServerNetwork.BOT_ID_BASE

	lobby = (load(FLAT_LOBBY) as PackedScene).instantiate()
	add_child(lobby)
	await get_tree().process_frame
	await get_tree().process_frame


func after_test() -> void:
	lobby.queue_free()
	await get_tree().process_frame
	ClientNetwork.reset_network()


# This process is both the server and the local client here, so the local
# player carries the server's own id
func _join_as_host() -> void:
	var raw := GameData.create_new_player_raw_data(multiplayer.get_unique_id(), PlatformTypeUtils.PlatformType.FlatDesktop, "Host", FugitiveTeamResolver.PlayerType.Seeker)
	raw.is_host = true
	ClientNetwork.on_register_player(raw)
	await get_tree().process_frame


func test_only_the_host_sees_the_add_bot_button() -> void:
	assert_object(lobby.addBotButton).is_not_null()
	assert_bool(lobby.addBotButton.visible).is_false()

	await _join_as_host()

	assert_bool(lobby.addBotButton.visible).is_true()
	assert_bool(lobby.addBotButton.disabled).is_false()


# The VR lobby panel inherits the same client lobby scene, so the button and
# its wiring come along without a separate copy
func test_the_vr_lobby_carries_the_same_button() -> void:
	var vr_lobby: Lobby = (load(VR_LOBBY_UI) as PackedScene).instantiate()
	add_child(vr_lobby)
	auto_free(vr_lobby)
	await get_tree().process_frame

	assert_object(vr_lobby.addBotButton).is_not_null()
	assert_bool(vr_lobby.addBotButton.pressed.is_connected(vr_lobby._on_AddBotButton_pressed)).is_true()


func test_an_added_bot_appears_in_the_player_list() -> void:
	await _join_as_host()
	ServerNetwork.on_add_bot()
	await get_tree().process_frame

	var botId: int = GameData.get_bot_player_ids()[0]
	var item = lobby.find_player_node(botId)
	assert_object(item).is_not_null()
	assert_str(item.get_node("Controls/NameLabel").text).contains("AI Fugitive")
	assert_str(item.get_node("Controls/PlatformIndicator").texture.resource_path).ends_with("client_type_bot.png")


func test_a_bot_cannot_switch_team_or_become_host() -> void:
	await _join_as_host()
	ServerNetwork.on_add_bot()
	await get_tree().process_frame

	var botId: int = GameData.get_bot_player_ids()[0]
	var item = lobby.find_player_node(botId)
	assert_bool(item.teamButton.disabled).is_true()
	assert_int(item.teamButton.selected).is_equal(FugitiveTeamResolver.PlayerType.Hider)
	assert_bool(item.get_node("Controls/HostMenuButton").get_popup().is_item_disabled(0)).is_true()

	var host_item = lobby.find_player_node(multiplayer.get_unique_id())
	assert_bool(host_item.teamButton.disabled).is_false()


func test_the_button_stops_when_the_fugitive_team_is_full() -> void:
	await _join_as_host()
	var maxHiders: int = Maps.get_team_sizes_for_map(LITTLETON)[FugitiveTeamResolver.PlayerType.Hider]
	for ii in maxHiders:
		ServerNetwork.on_add_bot()
	await get_tree().process_frame

	assert_int(lobby.playerList.get_child_count()).is_equal(maxHiders + 1)
	assert_bool(lobby.addBotButton.disabled).is_true()


func test_kicking_a_bot_removes_it_from_the_list() -> void:
	await _join_as_host()
	ServerNetwork.on_add_bot()
	await get_tree().process_frame
	var botId: int = GameData.get_bot_player_ids()[0]

	lobby.on_kick_player(botId)
	ServerNetwork.on_kick_player(botId)
	await get_tree().process_frame
	await get_tree().process_frame

	assert_object(lobby.find_player_node(botId)).is_null()
	assert_int(lobby.playerList.get_child_count()).is_equal(1)


func test_the_difficulty_picker_offers_every_level_and_starts_on_medium() -> void:
	assert_object(lobby.botDifficulty).is_not_null()
	assert_int(lobby.botDifficulty.item_count).is_equal(AiDifficulty.Level.size())
	assert_int(lobby.selected_bot_difficulty()).is_equal(AiDifficulty.Level.MEDIUM)
	assert_bool(lobby.botDifficulty.visible).is_false()

	await _join_as_host()

	assert_bool(lobby.botDifficulty.visible).is_true()


# The VR lobby inherits the same client lobby scene, so the picker comes along
func test_the_vr_lobby_carries_the_difficulty_picker() -> void:
	var vr_lobby: Lobby = (load(VR_LOBBY_UI) as PackedScene).instantiate()
	add_child(vr_lobby)
	auto_free(vr_lobby)
	await get_tree().process_frame

	assert_object(vr_lobby.botDifficulty).is_not_null()
	assert_int(vr_lobby.botDifficulty.item_count).is_equal(AiDifficulty.Level.size())


func test_the_host_adds_a_bot_at_the_picked_difficulty() -> void:
	await _join_as_host()
	lobby.botDifficulty.select(lobby.botDifficulty.get_item_index(AiDifficulty.Level.HARD))
	assert_int(lobby.selected_bot_difficulty()).is_equal(AiDifficulty.Level.HARD)

	# The button sends an RPC to the server, which a server never delivers to
	# itself, so the request is handed over the way the server receives it
	ServerNetwork.on_add_bot(lobby.selected_bot_difficulty())
	await get_tree().process_frame
	await get_tree().process_frame

	var bots := GameData.get_bot_player_ids()
	assert_int(bots.size()).is_equal(1)
	assert_int(GameData.get_player(bots[0]).get_bot_difficulty()).is_equal(AiDifficulty.Level.HARD)
	assert_str(lobby.find_player_node(bots[0]).get_node("Controls/NameLabel").text).contains("Hard")
