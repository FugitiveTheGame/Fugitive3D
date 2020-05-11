extends Node
class_name FugitiveHistoryCollection

var stateHistoryArray := []

remotesync func on_history_heartbeat(heartbeat: Array):
	stateHistoryArray.append(heartbeat)
	print("Hearbeat Recieved: %f %s" % [ heartbeat[0].position.x, heartbeat[0].entryType ])

func reset():
	stateHistoryArray.clear()
