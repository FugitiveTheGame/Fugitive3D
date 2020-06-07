extends VoiceChatReceiver
class_name VoiceChatTransceiver


var effect: AudioEffectRecord
var maxTeamHearingRange := 10.0
var maxHearingRange := 30.0

onready var opus_encoder := $OpusEncoder
onready var transmit_limit_timer := $TransmitLimitTimer as Timer
onready var transmit_limit_audio := $TransmitLimitAudio as AudioStreamPlayer



func _ready():
	var idx := AudioServer.get_bus_index("Record")
	effect = AudioServer.get_bus_effect(idx, 0) as AudioEffectRecord


func _input(event):
	if event.is_action_pressed("push_to_talk"):
		if not effect.is_recording_active():
			print("Start recording")
			effect.set_recording_active(true)
			transmit_limit_timer.start()
	elif event.is_action_released("push_to_talk"):
		transmit_limit_timer.stop()
		transmit_audio()


func transmit_audio():
	if effect.is_recording_active():
		print("Stop recording")
		transmit_limit_timer.stop()
		
		var recording := effect.get_recording()
		effect.set_recording_active(false)
		
		print("Received audio of size:")
		print(recording.data.size())
		
		send_audio(recording.data)


# This should be overriden to determine who the audio is sent to based on game
# rules
func send_audio(audioData: PoolByteArray):
	pass


func _on_TransmitLimitTimer_timeout():
	transmit_limit_audio.play()
	transmit_audio()


func is_recording() -> bool:
	return effect.is_recording_active()
