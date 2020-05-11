extends Control


# Called when the node enters the scene tree for the first time.
func populate(playerInfoData: PlayerData, playerObj: FugitivePlayer):
	var playerType := playerInfoData.get_type()
	var team = GameData.currentGame.get_team_name(playerType)
	
	$PlayerNameLabel.text = playerInfoData.get_name()
	
	if playerObj.playerType == FugitiveTeamResolver.PlayerType.Hider:
		var frozen: String
		if playerObj.frozen:
			$PlayerNameLabel.text += " [Captured]"
		else:
			$PlayerNameLabel.text += " [ESCAPED!]"
		
		add_stat(playerInfoData, FugitivePlayerDataUtility.STAT_HIDER_FROZEN)
		add_stat(playerInfoData, FugitivePlayerDataUtility.STAT_HIDER_UNFROZEN)
		add_stat(playerInfoData, FugitivePlayerDataUtility.STAT_HIDER_UNFREEZER)
	else:
		add_stat(playerInfoData, FugitivePlayerDataUtility.STAT_SEEKER_FREEZES)


func add_stat(playerInfoData: PlayerData, statKey: String):
	var stat := FugitivePlayerDataUtility.get_match_stat(playerInfoData, statKey)
	var statName := FugitivePlayerDataUtility.get_stat_name(statKey)
	add_stat_ui(statName, stat)


func add_stat_ui(statName: String, statValue: int):
	var nameLabel = Label.new()
	nameLabel.text = "%s: " % statName
	$PanelContainer/StatsContainer.add_child(nameLabel)
	
	var valueLabel = Label.new()
	valueLabel.text = str(statValue)
	$PanelContainer/StatsContainer.add_child(valueLabel)
