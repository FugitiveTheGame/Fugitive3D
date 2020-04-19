extends Control

var playerInfo = null

func populate(player, is_starting: bool, is_host: bool):
	playerInfo = player
	
	var playerId = playerInfo[GameData.PLAYER_ID]
	
	$NameLabel.text = playerInfo[GameData.PLAYER_NAME]
	$HostLabel.visible = playerInfo[GameData.PLAYER_HOST]
	
	var playerType = playerInfo[GameData.PLAYER_TYPE]
	match playerType:
		GameData.PlayerType.Hider:
			$TeamButton.selected = 0
		GameData.PlayerType.Seeker:
			$TeamButton.selected = 1
	
	if (is_host or ClientNetwork.is_local_player(playerId)) and not is_starting:
		$TeamButton.disabled = false
	else:
		$TeamButton.disabled = true


func _on_TeamButton_item_selected(id):
	var newType: int
	
	match id:
		0:
			newType = GameData.PlayerType.Hider
		1:
			newType = GameData.PlayerType.Seeker
	
	ServerNetwork.change_player_type(playerInfo[GameData.PLAYER_ID], newType)
