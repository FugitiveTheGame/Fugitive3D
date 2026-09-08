extends GdUnitTestSuite

# The game pauses the tree while a level loads. A paused AudioStreamPlayer
# reports itself as not playing, and re-playing the microphone during that
# window tears down the old capture stream and freezes the input buffer.


func after_test() -> void:
	get_tree().paused = false


func test_the_microphone_keeps_running_through_a_tree_pause() -> void:
	assert_int(Microphone.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)
	
	Microphone.start()
	await await_idle_frame()
	var playback := Microphone.player.get_stream_playback()
	assert_object(playback).is_not_null()
	
	get_tree().paused = true
	await await_idle_frame()
	assert_bool(Microphone.player.playing).override_failure_message("the microphone player paused with the tree").is_true()
	
	Microphone.start()
	get_tree().paused = false
	await await_idle_frame()
	
	assert_object(Microphone.player.get_stream_playback()).override_failure_message("start() replaced the microphone playback").is_same(playback)
