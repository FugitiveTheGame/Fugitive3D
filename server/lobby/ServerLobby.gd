extends "res://common/lobby/Lobby.gd"

onready var advertiser := $ServerAdvertiser as ServerAdvertiser
var serverPort: int
var serverName: String


func _enter_tree():
	serverPort = get_port()
	serverName = get_name()
	
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
	advertiser.serverInfo["port"] = serverPort
	advertiser.serverInfo["name"] = serverName
	advertiser.serverInfo["game_version"] = UserData.GAME_VERSION
	advertiser.serverRepositoryUrl = ServerNetwork.SERVER_REPOSITORY_URL
	
	if get_public():
		advertiser.start_advertising_publicly()


func on_start_game():
	var mapId = GameData.general[GameData.GENERAL_MAP]
	get_tree().change_scene(Maps.get_game_scene(mapId, Maps.TYPE_SERVER))


# Parse command line server name in the form of:
# --name xxxxx
func get_name() -> String:
	var name := "Fugitive 3D Server"
	
	var args := OS.get_cmdline_args()
	for ii in range(args.size()):
		var arg = args[ii]
		if arg.nocasecmp_to("--name") == 0:
			var next = ii+1
			if args.size() > next:
				var newName = args[next]
				if newName.length() > 0 and newName.length() < 32:
					name = newName
					print("User specified name: %s" % name)
				else:
					print("Invalid server name length")
				
				break
	
	return name


# Parse command line port in the form of:
# --port xxxxx
func get_port() -> int:
	var port = ServerNetwork.SERVER_PORT
	
	var args := OS.get_cmdline_args()
	for ii in range(args.size()):
		var arg = args[ii]
		if arg.nocasecmp_to("--port") == 0:
			var next = ii+1
			if args.size() > next:
				var newPortStr = args[next]
				var newPort := int(newPortStr)
				if newPort != 0:
					port = newPort
					print("User specified port: %d" % port)
					break
	
	return port


# Parse command line port in the form of:
# --public
func get_public() -> bool:
	var public := false
	
	var args := OS.get_cmdline_args()
	for arg in args:
		if arg.nocasecmp_to("--public") == 0:
			public = true
			break
	
	return public

func on_start_lobby_countdown():
	.on_start_lobby_countdown()
	
	# Don't allow any more connections now that we're in the terminal count
	get_tree().network_peer.refuse_new_connections = true
	
	# Make sure we don't show up in the repository while we're playing
	advertiser.remove_from_repository()
