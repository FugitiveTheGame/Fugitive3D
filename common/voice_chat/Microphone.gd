extends Node

# Thar be dragons: Godot keeps one global microphone activation flag, and a
# stopped AudioStreamMicrophone playback releases it on the audio thread some
# frames later. Two microphone playbacks overlapping, whether from two players
# or from re-playing this one, leave the survivor reading a frozen input buffer
# on a loop. This node therefore runs while the tree is paused, so the player
# never reports itself stopped, and start() only ever plays once.

const BUS := &"Record"
const RECORD_AUDIO_PERMISSION := "RECORD_AUDIO"

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
	
	# Android answers the first request with a dialog and a refusal, and a mic
	# started under that refusal leaves Godot's input flag stuck until relaunch
	if OS.get_name() == "Android" and not OS.request_permission(RECORD_AUDIO_PERMISSION):
		get_tree().on_request_permissions_result.connect(_on_permission_result)
		return
	
	player.play()


func _on_permission_result(permission: String, granted: bool):
	# The result carries the full android.permission name
	if not permission.ends_with(RECORD_AUDIO_PERMISSION) or not granted:
		return
	get_tree().on_request_permissions_result.disconnect(_on_permission_result)
	player.play()
