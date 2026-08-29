extends Node

signal remove_player

func _ready():
	multiplayer.peer_disconnected.connect(_player_disconnected)


func _exit_tree():
	multiplayer.peer_disconnected.disconnect(_player_disconnected)


# Every network peer needs to clean up the disconnected client
func _player_disconnected(id):
	print("Player disconnected: " + str(id))
	GameData.remove_player(id)
	
	emit_signal("remove_player", id)
	print("Total players: %d" % GameData.players.size())


# Completely reset the game state and clear the network
func reset_network():
	if Utils.has_active_network_peer(multiplayer):
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = null
	
	# Cleanup all state related to the game session
	GameData.reset()
