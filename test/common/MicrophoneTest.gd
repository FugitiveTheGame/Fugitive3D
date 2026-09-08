extends GdUnitTestSuite

# Godot exposes one global microphone activation flag, so two
# AudioStreamMicrophone players overlapping across the lobby-to-game scene
# change leave the survivor looping a frozen capture buffer. The Microphone
# autoload owns the only microphone player and transceivers must not bring
# their own.

const TRANSCEIVER_SCENES := [
	"res://common/lobby/voip/LobbyLocalVoiceChat.tscn",
	"res://common/game/mode/fugitive/FugitiveVoiceTransceiver.tscn",
]


func test_the_autoload_owns_the_microphone_player() -> void:
	assert_object(Microphone.player.stream).is_instanceof(AudioStreamMicrophone)
	assert_str(String(Microphone.player.bus)).is_equal("Record")
	
	var record := AudioServer.get_bus_index("Record")
	assert_object(Microphone.capture).is_same(AudioServer.get_bus_effect(record, 0))


func test_transceiver_scenes_carry_no_microphone_player() -> void:
	for path in TRANSCEIVER_SCENES:
		var root: Node = auto_free(load(path).instantiate())
		assert_array(_microphone_players(root)).override_failure_message(path).is_empty()


func test_a_transceiver_shares_the_autoload_capture() -> void:
	var voip: Node = auto_free(load(TRANSCEIVER_SCENES[0]).instantiate())
	add_child(voip)
	
	var transceiver := voip.get_node("VoiceChat") as VoiceChatTransceiver
	assert_object(transceiver.capture).is_same(Microphone.capture)


func _microphone_players(node: Node) -> Array:
	var found := []
	if node is AudioStreamPlayer and node.stream is AudioStreamMicrophone:
		found.append(node)
	for child in node.get_children():
		found.append_array(_microphone_players(child))
	return found
