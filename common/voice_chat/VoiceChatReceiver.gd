extends Spatial
class_name VoiceChatReceiver

onready var audioPlayer := $AudioStreamPlayBack as AudioStreamPlayer3D
onready var opus_decoder := $OpusDecoder


func send_audio(audioData: PoolByteArray):
	rpc("on_receive_audio", audioData)


remote func on_receive_audio(audioData: PoolByteArray):
	print("Received audio size encoded: %d" % audioData.size())
	var pcm_data = opus_decoder.decode(audioData)
	print("Received audio size decoded: %d" % pcm_data.size())
	
	audioPlayer.stream.data = pcm_data
	audioPlayer.play()
