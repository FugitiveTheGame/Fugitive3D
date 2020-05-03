extends Panel

export(NodePath) var playerListPath: NodePath
onready var playerList := get_node(playerListPath) as VBoxContainer


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
				
			var playerStats = FugitivePlayerDataUtility.get_stats(playerInfoData)
			print("Player stat count: %d" % playerStats.size())
			for stat in playerStats.keys():
				node.text += "\n\t%s: %d" % [stat, playerStats[stat]]
			
			playerList.add_child(node)
	
	show()
	
	$GameOverAudio.play()
