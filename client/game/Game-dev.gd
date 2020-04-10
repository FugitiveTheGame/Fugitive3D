extends "res://client/game/flat/FlatClientGame.gd"


# Start a local server, the whole game expects to be multiplayer
func _enter_tree():
	var peer := NetworkedMultiplayerENet.new()
	var result := peer.create_server(5555, 5)
	peer.refuse_new_connections = true
	get_tree().set_network_peer(peer)
	
	GameData.add_player(1, "real player", GameData.PlayerType.Seeker)
	GameData.add_player(2, "dumb donkey 0", GameData.PlayerType.Hider)
	GameData.add_player(3, "dumb donkey 1", GameData.PlayerType.Hider)


func _ready():
	get_tree().paused = false


# Load the dev map
func load_map():
	var scene := load("res://common/game/maps/test_map_01/TestMap01.tscn")
	game = scene.instance()
	add_child(game)
	players = game.find_node("Players")
