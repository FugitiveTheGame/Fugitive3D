extends Control

func _ready():
	$Container/HidersLabel.hide()
	$Container/SeekersLabel.hide()
	
	hide()


func team_won(winningTeam: int):
	match winningTeam:
		GameData.PlayerType.Hider:
			$Container/HidersLabel.show()
			$Container/SeekersLabel.hide()
		GameData.PlayerType.Seeker:
			$Container/HidersLabel.hide()
			$Container/SeekersLabel.show()
		_:
			print("Invalid winning team: %d" % winningTeam)
			assert(false)
	
	for playerInfo in GameData.get_players():
		var node := Label.new()
		var playerType := playerInfo[GameData.PLAYER_TYPE] as int
		var team := GameData.currentGame.get_team_name(playerType)
		
		var playerObj := GameData.currentGame.get_player(playerInfo[GameData.PLAYER_ID]) as FugitivePlayer
		if playerObj != null:
			var frozen: String
			if playerObj.frozen:
				frozen = "Captured"
			else:
				frozen = "ESCAPED!"
			
			if playerType == GameData.PlayerType.Hider:
				node.text = "[%s] %s - %s" % [team, playerInfo[GameData.PLAYER_NAME], frozen]
			else:
				node.text = "[%s] %s" % [team, playerInfo[GameData.PLAYER_NAME]]
			
			$Container/PlayerList.add_child(node)
	
	show()
