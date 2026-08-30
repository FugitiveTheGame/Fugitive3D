extends VoiceChatTransceiver


func send_audio(sequence: int, packet: PackedByteArray):
	var localPlayer := GameData.currentGame.localPlayer
	var localPlayerPos := localPlayer.global_transform.origin
	
	for playerId in GameData.currentGame.players:
		if playerId != GameData.currentGame.localPlayer.id:
			var player := GameData.currentGame.players[playerId] as Player
			
			if GameData.currentGame != null and not GameData.currentGame.is_game_over():
				if player.is_on_local_players_team():
					# Team mate is within ear shot
					if localPlayerPos.distance_to(player.global_transform.origin) <= maxTeamHearingRange:
						rpc_id(playerId, "on_receive_audio", sequence, packet)
					# If team member is out of range, hear it locally as if by radio
					else:
						player.playerVoiceChat.rpc_id(playerId, "on_receive_audio", sequence, packet)
				# Enemy is within ear shot
				elif localPlayerPos.distance_to(player.global_transform.origin) <= maxHearingRange:
					rpc_id(playerId, "on_receive_audio", sequence, packet)
			# If game is over, all players can hear each other regaurdless of distance
			else:
				player.playerVoiceChat.rpc_id(playerId, "on_receive_audio", sequence, packet)
