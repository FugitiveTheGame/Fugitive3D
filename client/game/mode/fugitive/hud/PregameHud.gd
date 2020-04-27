extends Control

onready var startTimer: Timer = get_tree().get_nodes_in_group(Groups.START_TIMER)[0]
onready var headstartTimer: Timer = get_tree().get_nodes_in_group(Groups.HEADSTART_TIMER)[0]


func _ready():
	if OS.has_feature("vr"):
		$NotReadyLabel.text = "Press TRIGGER to ready up"
	else:
		$NotReadyLabel.text = "Press JUMP to ready up"
	
	
	var teamName := GameData.currentGame.get_team_name(GameData.get_current_player_type())
	$PlayerClassLabel.text = "You are a: %s" % teamName
	
	$NotReadyLabel.show()
	$ReadyLabel.hide()
	$StartTimerLabel.hide()
	$HeadstartTimerLabel.hide()


func show_ready():
	$NotReadyLabel.hide()
	$ReadyLabel.show()
	$StartTimerLabel.hide()
	$HeadstartTimerLabel.hide()


func show_start_timer():
	$NotReadyLabel.hide()
	$ReadyLabel.hide()
	$StartTimerLabel.show()
	$HeadstartTimerLabel.hide()


func show_headstart_timer():
	$NotReadyLabel.hide()
	$ReadyLabel.hide()
	$StartTimerLabel.hide()
	$HeadstartTimerLabel.show()


func start_play_phase():
	$CopsReleasedAudio.play()
	hide()


func _process(delta):
	$StartTimerLabel.text = "Game starting: %s" % TimeUtils.format_seconds_for_display(startTimer.time_left)
	$HeadstartTimerLabel.text = "Cops released in: %s" % TimeUtils.format_seconds_for_display(headstartTimer.time_left)
