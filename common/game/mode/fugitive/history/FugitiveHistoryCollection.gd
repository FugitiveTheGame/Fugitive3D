extends Node
class_name FugitiveHistoryCollection

var stateHistoryArray := []
var player_summaries := {}

remotesync func on_history_heartbeat(heartbeat: Dictionary):
	stateHistoryArray.append(heartbeat)

func reset():
	stateHistoryArray.clear()

func loadPlayers(players : Dictionary):
	player_summaries = players.duplicate()
