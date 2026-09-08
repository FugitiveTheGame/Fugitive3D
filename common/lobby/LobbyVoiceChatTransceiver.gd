extends VoiceChatTransceiver


func send_audio(sequence: int, packet: PackedByteArray):
	var localPlayerId = multiplayer.get_unique_id()
	var peers := multiplayer.get_peers()
	
	# Send to every connected peer except ourselves; bots have no peer
	for playerId in GameData.players:
		if playerId != localPlayerId and playerId in peers:
			rpc_id(playerId, "on_receive_audio", sequence, packet)
