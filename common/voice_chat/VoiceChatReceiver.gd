extends Node
class_name VoiceChatReceiver

export(NodePath) var audioPlayerPath: NodePath
onready var audioPlayer := get_node(audioPlayerPath)

onready var opus_decoder := $OpusDecoder

const MAX_CLIPS := 5
var audio_clips := []


func _ready():
	var audioStream := AudioStreamSample.new()
	audioStream.stereo = true
	audioStream.format = AudioStreamSample.FORMAT_16_BITS
	audioStream.mix_rate = 44100
	
	audioPlayer.stream = audioStream
	
	audioPlayer.connect("finished", self, "on_audio_finished")


func send_audio(audioData: PoolByteArray):
	rpc("on_receive_audio", audioData)


remote func on_receive_audio(audioData: PoolByteArray):
	var pcm_data = opus_decoder.decode(audioData)
	
	if audio_clips.size() < MAX_CLIPS:
		audio_clips.push_back(pcm_data)
		play_next_clip()
	else:
		print("Dropping audio clip, too many in queue already")


func is_playing() -> bool:
	return audioPlayer.playing as bool


func play_next_clip():
	if not is_playing() and not audio_clips.empty():
		var clip = audio_clips.pop_front()
		
		audioPlayer.stream.data = clip
		audioPlayer.play()


func on_audio_finished():
	play_next_clip()
