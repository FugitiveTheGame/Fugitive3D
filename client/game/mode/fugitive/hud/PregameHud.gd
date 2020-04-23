extends Control

onready var startTimer: Timer = get_tree().get_nodes_in_group(Groups.START_TIMER)[0]
onready var headstartTimer: Timer = get_tree().get_nodes_in_group(Groups.HEADSTART_TIMER)[0]


func _ready():
	if OS.has_feature("vr"):
		$Container/NotReadyLabel.text = "Press TRIGGER to ready up"
	else:
		$Container/NotReadyLabel.text = "Press JUMP to ready up"
	
	
	var teamName := GameData.currentGame.get_team_name(GameData.get_current_player_type())
	$Container/PlayerClassLabel.text = "You are a: %s" % teamName
	
	$Container/NotReadyLabel.show()
	$Container/ReadyLabel.hide()
	$Container/StartTimerLabel.hide()
	$Container/HeadstartTimerLabel.hide()


func show_ready():
	$Container/NotReadyLabel.hide()
	$Container/ReadyLabel.show()
	$Container/StartTimerLabel.hide()
	$Container/HeadstartTimerLabel.hide()


func show_start_timer():
	$Container/NotReadyLabel.hide()
	$Container/ReadyLabel.hide()
	$Container/StartTimerLabel.show()
	$Container/HeadstartTimerLabel.hide()


func show_headstart_timer():
	$Container/NotReadyLabel.hide()
	$Container/ReadyLabel.hide()
	$Container/StartTimerLabel.hide()
	$Container/HeadstartTimerLabel.show()


func _process(delta):
	$Container/StartTimerLabel.text = "Game starting: %s" % TimeUtils.format_seconds_for_display(startTimer.time_left)
	$Container/HeadstartTimerLabel.text = "Cops released in: %s" % TimeUtils.format_seconds_for_display(headstartTimer.time_left)
