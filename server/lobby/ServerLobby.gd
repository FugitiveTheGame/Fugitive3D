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
	get_tree().network_peer.refuse_new_connections = true


func _ready():
	advertiser.serverInfo["port"] = serverPort
	advertiser.serverInfo["name"] = serverName
	advertiser.serverRepositoryUrl = ServerNetwork.SERVER_REPOSITORY_URL + "/register"
	
	if get_public():
		advertiser.start_advertising_publicly()


func on_start_game():
	get_tree().change_scene("res://server/game/mode/fugitive/ServerFugitiveGame.tscn")


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
	var port := ServerNetwork.SERVER_PORT
	
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
