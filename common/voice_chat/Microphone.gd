extends Node

# Thar be dragons: Godot keeps one global microphone activation flag, and a
# stopped AudioStreamMicrophone playback releases it on the audio thread some
# frames later. Two microphone players overlapping across a scene change leave
# the survivor reading a frozen input buffer on a loop, so the app holds this
# single player for its whole life and never stops it.

const BUS := &"Record"

var capture: AudioEffectCapture
var player: AudioStreamPlayer


func _ready():
	var idx := AudioServer.get_bus_index(BUS)
	capture = AudioServer.get_bus_effect(idx, 0) as AudioEffectCapture
	
	player = AudioStreamPlayer.new()
	player.stream = AudioStreamMicrophone.new()
	player.bus = BUS
	add_child(player)


func start():
	if not player.playing:
		player.play()
