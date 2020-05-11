extends PanelContainer

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

export(NodePath) var replayLegendPath: NodePath
onready var replayLegend := get_node(replayLegendPath) as VBoxContainer

func _ready():
	hide()


func team_won(winningTeam: int):
	
	var winningTeamName = GameData.currentGame.get_team_name(winningTeam)
	$Container/WinnerLabel.text = "%ss won!" % winningTeamName
	
	var headerListItem := preload("res://client/game/mode/fugitive/hud/StatsHeader.tscn")
	var playerStatsListItemScene := preload("res://client/game/mode/fugitive/hud/PlayerStatsListItem.tscn")
	
	var seekers = get_tree().get_nodes_in_group(Seeker.GROUP)
	var hiders = get_tree().get_nodes_in_group(Hider.GROUP)
	
	# Rendering seekers
	var header := headerListItem.instance()
	header.set_text( FugitiveTeamResolver.get_team_name(FugitiveTeamResolver.PlayerType.Seeker) + "s" )
	playerList.add_child(header)
	
	for playerObj in seekers:
		var playerInfoData := GameData.get_player(playerObj.id)
		if playerObj != null:
			var playerStatsListItem := playerStatsListItemScene.instance()
			playerStatsListItem.populate(playerInfoData, playerObj)
			playerList.add_child(playerStatsListItem)
	
	# Render hiders
	header = headerListItem.instance()
	header.set_text( FugitiveTeamResolver.get_team_name(FugitiveTeamResolver.PlayerType.Hider) + "s" )
	playerList.add_child(header)
	
	for playerObj in hiders:
		var playerInfoData := GameData.get_player(playerObj.id)
		if playerObj != null:
			var playerStatsListItem := playerStatsListItemScene.instance()
			playerStatsListItem.populate(playerInfoData, playerObj)
			playerList.add_child(playerStatsListItem)
	
	# Setup history map
	replayHud.stop()
	replayHud.setIndex(0)
	replayScrubSlider.value = 0
	replayScrubSlider.max_value = replayHud.getMaxFrameIndex()
	replaySpeedSlider.value = 1
	replayHud.setFrameSpeed(1.0)
	replayHud.loadReplayLegend(replayLegend)
	
	show()
	
	$GameOverAudio.play()


func _process(delta):
	replayScrubSlider.value = replayHud.getIndex()
	replayLabelHistory.text = "History: %s" % TimeUtils.format_seconds_for_display(replayScrubSlider.value)


func _on_ToLobbyButton_pressed():
	GameData.currentGame.go_to_lobby()


func _on_Scrub_value_changed(value):
	replayHud.setIndex(int(round(value)))
	replayLabelHistory.text = "History: %s" % TimeUtils.format_seconds_for_display(value)


func _on_Speed_value_changed(value):
	replayHud.setFrameSpeed(value)
	replayLabelSpeed.text = "Speed: %dx" % int(value)


func _on_ButtonHistoryPlay_pressed():
	if replayHud.togglePlay():
		replayPlayButton.text = "Pause"
	else:
		replayPlayButton.text = "Play"
