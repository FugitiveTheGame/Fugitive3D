extends Control

var playerInfo = null

func populate(player):
	playerInfo = player
	
	$NameLabel.text = playerInfo[GameData.PLAYER_NAME]
	$HostLabel.visible = playerInfo[GameData.PLAYER_HOST]
