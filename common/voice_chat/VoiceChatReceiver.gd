extends Node
class_name VoiceChatReceiver

@export var audioPlayerPath: NodePath
@onready var audioPlayer := get_node(audioPlayerPath)

@onready var opus_decoder := $OpusDecoder

const MAX_CLIPS := 5
var audio_clips := []


func _ready():
	var audioStream := AudioStreamWAV.new()
	audioStream.stereo = true
	audioStream.format = AudioStreamWAV.FORMAT_16_BITS
	audioStream.mix_rate = 44100
	
	audioPlayer.stream = audioStream
	
	audioPlayer.connect("finished", Callable(self, "on_audio_finished"))


func _exit_tree():
	audio_clips.clear()


func send_audio(audioData: PackedByteArray):
	rpc("on_receive_audio", audioData)


@rpc("any_peer") func on_receive_audio(audioData: PackedByteArray):
	if not audioData.is_empty():
		var pcm_data = opus_decoder.decode(audioData)
		
		if audio_clips.size() < MAX_CLIPS:
			if not pcm_data.is_empty():
				audio_clips.push_back(pcm_data)
				play_next_clip()
			else:
				push_warning("Decoded PCM data was empty")
		else:
			print("Dropping audio clip, too many in queue already")
	else:
		push_warning("Received empty opus packet.")


func is_playing() -> bool:
	return audioPlayer.playing as bool


func play_next_clip():
	if not is_playing() and not audio_clips.is_empty():
		var clip = audio_clips.pop_front()
		
		audioPlayer.stream.data = clip
		audioPlayer.play()


func on_audio_finished():
	play_next_clip()
