extends Control

func _ready():
	hide()

func team_won(winningTeam: int):
	
	var winningTeamName = GameData.currentGame.get_team_name(winningTeam)
	$Container/WinnerLabel.text = "%ss won!" % winningTeamName
	
	for playerInfo in GameData.get_players():
		var playerInfoData := playerInfo as PlayerData
		var node := Label.new()
		var playerType := playerInfoData.get_type()
		var team = GameData.currentGame.get_team_name(playerType)
		
		var playerObj := GameData.currentGame.get_player(playerInfoData.get_id()) as FugitivePlayer
		if playerObj != null:
			var frozen: String
			if playerObj.frozen:
				frozen = "Captured"
			else:
				frozen = "ESCAPED!"
			
			if playerType == FugitiveTeamResolver.PlayerType.Hider:
				node.text = "[%s] %s - %s" % [team, playerInfo.get_name(), frozen]
			else:
				node.text = "[%s] %s" % [team, playerInfo.get_name()]
			
			$Container/PlayerList.add_child(node)
	
	show()
	
	$GameOverAudio.play()
