extends Node

# Thar be dragons: Godot keeps one global microphone activation flag, and a
# stopped AudioStreamMicrophone playback releases it on the audio thread some
# frames later. Two microphone playbacks overlapping, whether from two players
# or from re-playing this one, leave the survivor reading a frozen input buffer
# on a loop. This node therefore runs while the tree is paused, so the player
# never reports itself stopped, and start() only ever plays once.

const BUS := &"Record"

var capture: AudioEffectCapture
var player: AudioStreamPlayer
var started := false


func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	var idx := AudioServer.get_bus_index(BUS)
	capture = AudioServer.get_bus_effect(idx, 0) as AudioEffectCapture
	
	player = AudioStreamPlayer.new()
	player.stream = AudioStreamMicrophone.new()
	player.bus = BUS
	add_child(player)


func start():
	if started:
		return
	started = true
	player.play()
