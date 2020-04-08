extends "res://common/game/Game.gd"


# Start a local server, the whole game expects to be multiplayer
func _enter_tree():
	var peer := NetworkedMultiplayerENet.new()
	var result := peer.create_server(5555, 5)
	peer.refuse_new_connections = true
	get_tree().set_network_peer(peer)


# Load the dev map
func load_map():
	var scene := load("res://common/game/maps/test_map_00/TestMap00.tscn")
	game = scene.instance()
	add_child(game)
	players = game.find_node("Players")


# We don't want to do the normal setup
func pre_configure():
	print("DEV: skipping pre_configure()")
