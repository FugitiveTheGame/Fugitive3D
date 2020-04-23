extends Control

func _ready():
	$HidersLabel.hide()
	$SeekersLabel.hide()
	
	hide()


func teamName(playerType: int) -> String:
	
	var team: String
	match playerType:
		GameData.PlayerType.Hider:
			team = "Hider"
		GameData.PlayerType.Seeker:
			team = "Seeker"
		_:
			team = "---"
	
	return team


func team_won(winningTeam: int):
	match winningTeam:
		GameData.PlayerType.Hider:
			$HidersLabel.show()
			$SeekersLabel.hide()
		GameData.PlayerType.Seeker:
			$HidersLabel.hide()
			$SeekersLabel.show()
		_:
			print("Invalid winning team: %d" % winningTeam)
			assert(false)
	
	for playerInfo in GameData.get_players():
		var node := Label.new()
		var playerType := playerInfo[GameData.PLAYER_TYPE] as int
		var team := teamName(playerType)
		
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
			
			$PlayerList.add_child(node)
	
	show()
