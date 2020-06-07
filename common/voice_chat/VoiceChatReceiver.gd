extends Node
class_name VoiceChatReceiver

export(NodePath) var audioPlayerPath: NodePath
onready var audioPlayer := get_node(audioPlayerPath)

onready var opus_decoder := $OpusDecoder


func _ready():
	var audioStream := AudioStreamSample.new()
	audioStream.stereo = true
	audioStream.format = AudioStreamSample.FORMAT_16_BITS
	audioStream.mix_rate = 44100
	
	audioPlayer.stream = audioStream


func send_audio(audioData: PoolByteArray):
	rpc("on_receive_audio", audioData)


remote func on_receive_audio(audioData: PoolByteArray):
	var pcm_data = opus_decoder.decode(audioData)
	
	audioPlayer.stream.data = pcm_data
	audioPlayer.play()


func is_playing() -> bool:
	return audioPlayer.playing as bool
