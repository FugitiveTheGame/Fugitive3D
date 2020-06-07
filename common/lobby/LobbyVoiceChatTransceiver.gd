extends VoiceChatTransceiver


func send_audio(audioData: PoolByteArray):
	var encodedData = opus_encoder.encode(audioData)

	# Send to all players except our selves
	for playerId in GameData.currentGame.players:
		if playerId != GameData.currentGame.localPlayer.id:
			rpc_id(playerId,"on_receive_audio", encodedData)
