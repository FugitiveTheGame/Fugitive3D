extends Label

onready var gameTimer: Timer = get_tree().get_nodes_in_group(Groups.GAME_TIMER)[0] as Timer


func _on_UpdateTimer_timeout():
	text = str(gameTimer.time_left)
