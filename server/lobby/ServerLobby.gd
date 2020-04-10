extends "res://common/lobby/Lobby.gd"

func _ready():
	if not ServerNetwork.is_hosting():
		var port := get_port()
		if not ServerNetwork.host_game(port):
			print("Failed to start server, shutting down.")
			get_tree().quit()
			return
	
	ClientNetwork.connect("start_game", self, "on_start_game")


func on_start_game():
	get_tree().change_scene("res://server/game/mode/fugitive/ServerFugitiveGame.tscn")


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
