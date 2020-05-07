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
	advertiser.remove_from_repository()


func _ready():
	ServerUtils.configure_advertiser(advertiser, serverName, serverPort)
	advertiser.initial_registration = false
	
	if not ServerUtils.get_no_lan():
		advertiser.start_advertising_lan()
	
	if ServerUtils.get_public():
		advertiser.start_advertising_publicly()


func on_start_game():
	var mapId = GameData.general[GameData.GENERAL_MAP]
	get_tree().change_scene(Maps.get_game_scene(mapId, Maps.TYPE_SERVER))


func on_start_lobby_countdown():
	.on_start_lobby_countdown()
	
	# Don't allow any more connections now that we're in the terminal count
	get_tree().network_peer.refuse_new_connections = true
	
	# Make sure we don't show up in the repository while we're playing
	advertiser.remove_from_repository()
