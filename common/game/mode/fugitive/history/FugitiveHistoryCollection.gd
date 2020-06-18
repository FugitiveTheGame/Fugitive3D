extends Node
class_name FugitiveHistoryCollection

var stateHistoryArray := []
var player_summaries := {}


func record_heartbeat(heartbeat: Dictionary):
	stateHistoryArray.append(heartbeat)


func reset():
	stateHistoryArray.clear()
	player_summaries.clear()


func loadPlayers(players : Dictionary):
	player_summaries = players.duplicate()
