extends VoiceChatTransceiver


func send_audio(encodedData: PackedByteArray):
	var localPlayerId = multiplayer.get_unique_id()
	
	# Send to all players except our selves
	for playerId in GameData.players:
		if playerId != localPlayerId:
			rpc_id(playerId,"on_receive_audio", encodedData)
