extends Panel

export(NodePath) var playerListPath: NodePath
onready var playerList := get_node(playerListPath) as VBoxContainer
export(NodePath) var replayScrubSliderPath: NodePath
onready var replayScrubSlider := get_node(replayScrubSliderPath) as HSlider
export(NodePath) var replaySpeedSliderPath: NodePath
onready var replaySpeedSlider := get_node(replaySpeedSliderPath) as HSlider
export(NodePath) var replayPlayButtonPath: NodePath
onready var replayPlayButton := get_node(replayPlayButtonPath) as Button
export(NodePath) var replayLabelHistoryPath: NodePath
onready var replayLabelHistory := get_node(replayLabelHistoryPath) as Label
export(NodePath) var replayLabelSpeedPath: NodePath
onready var replayLabelSpeed := get_node(replayLabelSpeedPath) as Label
export(NodePath) var replayHudPath: NodePath
onready var replayHud := get_node(replayHudPath) as HistoryMapHud

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
			for statKey in playerStats.keys():
				var statName := FugitivePlayerDataUtility.get_stat_name(statKey)
				var stat := FugitivePlayerDataUtility.get_stat(playerInfoData, statKey)
				node.text += "\n\t%s: %d" % [statName, stat]
			
			playerList.add_child(node)
	
	replayHud.stop()
	replayHud.setIndex(0)
	replayScrubSlider.value = 0
	replayScrubSlider.max_value = replayHud.getMaxFrameIndex()
	replaySpeedSlider.value = 1
	replayHud.setFrameSpeed(1.0)
	
	show()
	
	$GameOverAudio.play()

func _process(delta):
	replayScrubSlider.value = replayHud.getIndex()
	replayLabelHistory.text = "History: %fs" % replayScrubSlider.value

func _on_ToLobbyButton_pressed():
	GameData.currentGame.go_to_lobby()

func _on_Scrub_value_changed(value):
	replayHud.setIndex(round(value))
	replayLabelHistory.text = "History: %fs" % value

func _on_Speed_value_changed(value):
	replayHud.setFrameSpeed(value)
	replayLabelSpeed.text = "Speed: %fx" % value

func _on_ButtonHistoryPlay_pressed():
	if replayHud.togglePlay():
		replayPlayButton.text = "Pause"
	else:
		replayPlayButton.text = "Play"
