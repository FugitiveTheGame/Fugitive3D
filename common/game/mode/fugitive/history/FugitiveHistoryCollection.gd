extends Node
class_name FugitiveHistoryCollection

var stateHistoryArray := []

remotesync func on_history_heartbeat(heartbeat: Array):
	stateHistoryArray.append(heartbeat)

func reset():
	stateHistoryArray.clear()
