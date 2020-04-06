extends "res://common/game/Game.gd"

var unreadyPlayers := {}

func _ready():
	ClientNetwork.connect("remove_player", self, "server_remove_player")
	
	for playerId in GameData.players:
		unreadyPlayers[playerId] = playerId


func create_player_seeker_node() -> Node:
	print("create_player_seeker_node() MUST NOT BE CALLED ON SERVER")
	assert(false)
	return null


func create_player_hider_node() -> Node:
	print("create_player_hider_node() MUST NOT BE CALLED ON SERVER")
	assert(false)
	return null


remote func on_client_ready(playerId: int):
	print("client ready: %s" % playerId)
	unreadyPlayers.erase(playerId)
	print("Still waiting on %d players" % unreadyPlayers.size())
	
	# All clients are done, unpause the game
	if unreadyPlayers.empty():
		print("Starting the game")
		rpc("on_pre_configure_complete")


func server_remove_player(playerId: int):
	# If all players are gone, return to lobby
	if GameData.players.empty():
		print("All players disconnected, returning to lobby")
		get_tree().change_scene("res://server/lobby/ServerLobby.tscn")
	else:
		print("Players remaining: %d" % GameData.players.size())


func finish_game():
	.finish_game()
	print("SERVER: game is complete!")
	rpc("on_go_to_lobby")


remotesync func on_go_to_lobby():
	print("SERVER: on_go_to_lobby()")
	get_tree().change_scene("res://server/lobby/ServerLobby.tscn")
