extends "res://common/lobby/Lobby.gd"

onready var advertiser := $ServerAdvertiser as ServerAdvertiser
onready var reporter := ServerReporter.get_instance(get_tree()) as ServerReporter
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
	ServerNetwork.is_joinable = true


func _exit_tree():
	# Don't allow new connections if we're in-game
	if get_tree().network_peer != null:
		ServerNetwork.is_joinable = false
	
	ServerUtils.update_joinable(advertiser, ServerNetwork.is_joinable)


func _ready():
	ServerUtils.normal_start(advertiser, true)
	
	if reporter != null:
		reporter.configure(advertiser.externalIp, serverPort, serverName, UserData.GAME_VERSION)


func on_start_game():
	var mapId = GameData.general[GameData.GENERAL_MAP]
	get_tree().change_scene(Maps.get_game_scene(mapId, Maps.TYPE_SERVER))


func on_start_lobby_countdown():
	.on_start_lobby_countdown()
	
	# Don't allow any more connections now that we're in the terminal count
	ServerNetwork.is_joinable = false
	
	# Make sure we aren't joinable
	ServerUtils.update_joinable(advertiser, ServerNetwork.is_joinable)
	
	# We must ensure that the server loads before everyone else,
	# So while the cliets are counting down, send the server to the game
	# so it can get configured in time
	ClientNetwork.on_start_game()


func create_player(playerId: int):
	.create_player(playerId)
	advertiser.update_players(GameData.players.size())


func remove_player(playerId: int):
	.remove_player(playerId)
	advertiser.update_players(GameData.players.size())
