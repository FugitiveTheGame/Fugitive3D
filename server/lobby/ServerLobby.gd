extends "res://common/lobby/Lobby.gd"

onready var advertiser := $ServerAdvertiser as ServerAdvertiser
var serverPort: int
var serverName: String


func _enter_tree():
	serverPort = ServerUtils.get_port()
	serverName = ServerUtils.get_name()
	
	
	if not ServerNetwork.is_hosting():
		if not ServerNetwork.host_game(serverPort):
			print("Failed to start server, shutting down.")
			get_tree().quit()
			return
	
		# Allow new connections when we arrive back in the lobby
	get_tree().network_peer.refuse_new_connections = false


func _exit_tree():
	# Don't allow new connections if we're in-game
	if get_tree().network_peer != null:
		get_tree().network_peer.refuse_new_connections = true
	
	ServerUtils.update_joinable(advertiser, false)


func _ready():
	ServerUtils.normal_start(advertiser, true)


func on_start_game():
	var mapId = GameData.general[GameData.GENERAL_MAP]
	get_tree().change_scene(Maps.get_game_scene(mapId, Maps.TYPE_SERVER))


func on_start_lobby_countdown():
	.on_start_lobby_countdown()
	
	# Don't allow any more connections now that we're in the terminal count
	get_tree().network_peer.refuse_new_connections = true
	
	# Make sure we aren't joinable
	ServerUtils.update_joinable(advertiser, false)
	
	# We must ensure that the server loads before everyone else,
	# So while the cliets are counting down, send the server to the game
	# so it can get configured in time
	ClientNetwork.on_start_game()
