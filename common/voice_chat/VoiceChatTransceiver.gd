extends VoiceChatReceiver
class_name VoiceChatTransceiver


var capture: AudioEffectCapture
var maxTeamHearingRange := 10.0
var maxHearingRange := 40.0

@onready var opus_encoder := $OpusEncoder as OpusEncoderNode
@onready var transmit_limit_timer := $TransmitLimitTimer as Timer
@onready var transmit_limit_audio := $TransmitLimitAudio as AudioStreamPlayer

var transmitting := false
var packet_sequence := 0


func _ready():
	super._ready()
	var idx := AudioServer.get_bus_index("Record")
	capture = AudioServer.get_bus_effect(idx, 0) as AudioEffectCapture


func _input(event):
	if event.is_action_pressed("push_to_talk"):
		start_transmitting()
	elif event.is_action_released("push_to_talk"):
		stop_transmitting()


func _process(delta):
	super._process(delta)
	
	if not transmitting:
		return
	
	opus_encoder.push_audio(capture.get_buffer(capture.get_frames_available()))
	
	while opus_encoder.has_packet():
		var packet := opus_encoder.pop_packet()
		if not packet.is_empty():
			send_audio(packet_sequence, packet)
			packet_sequence += 1


func start_transmitting():
	if transmitting:
		return
	
	transmitting = true
	
	# Anything captured before the key went down is not part of this burst
	capture.clear_buffer()
	opus_encoder.reset_stream()
	
	transmit_limit_timer.start()


func stop_transmitting():
	if not transmitting:
		return
	
	transmitting = false
	transmit_limit_timer.stop()


# This should be overriden to determine who the audio is sent to based on game
# rules
func send_audio(sequence: int, packet: PackedByteArray):
	pass


func _on_TransmitLimitTimer_timeout():
	transmit_limit_audio.play()
	stop_transmitting()


func is_recording() -> bool:
	return transmitting
