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


func send_audio(audioData: PoolByteArray):
	print("Sent audio size raw: %d" % audioData.size())
	var encodedData = opus_encoder.encode(audioData)
	print("Sent audio size encoded: %d" % encodedData.size())
	
	var localPlayer := GameData.currentGame.localPlayer
	var localPlayerPos := localPlayer.global_transform.origin
	
	for playerId in GameData.currentGame.players:
		if playerId != GameData.currentGame.localPlayer.id:
			var player := GameData.currentGame.players[playerId] as Player
			
			if player.is_on_local_players_team():
				# Team mate is within ear shot
				if localPlayerPos.distance_to(player.global_transform.origin) <= maxTeamHearingRange:
					rpc_id(playerId,"on_receive_audio", encodedData)
				# If team member is out of range, hear it locally as if by radio
				else:
					player.playerVoiceChat.rpc_unreliable_id(playerId,"on_receive_audio", encodedData)
			# Enemy is within ear shot
			elif localPlayerPos.distance_to(player.global_transform.origin) <= maxHearingRange:
				rpc_id(playerId,"on_receive_audio", encodedData)


func _on_TransmitLimitTimer_timeout():
	transmit_limit_audio.play()
	transmit_audio()


func is_recording() -> bool:
	return effect.is_recording_active()
