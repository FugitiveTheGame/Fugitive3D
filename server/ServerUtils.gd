extends Object
class_name ServerUtils


static func normal_start(advertiser: ServerAdvertiser, joinable: bool):
	var public := get_public()
	
	configure_advertiser(advertiser, get_name(), get_port(), public, joinable)
	advertiser.initial_registration = false
	
	advertiser.update_players(GameData.players.size())
	
	if not get_no_lan():
		advertiser.start_advertising_lan()
	
	if public:
		advertiser.start_advertising_publicly()


static func update_joinable(advertiser: ServerAdvertiser, _joinable: bool):
	advertiser.serverInfo["is_joinable"] = _joinable
	advertiser.register_server()


static func configure_advertiser(advertiser: ServerAdvertiser, _name: String, _port: int, _public: bool, _joinable: bool):
	advertiser.serverInfo["port"] = _port
	advertiser.serverInfo["name"] = _name
	advertiser.serverInfo["is_joinable"] = _joinable
	advertiser.serverInfo["game_version"] = UserData.GAME_VERSION
	advertiser.serverRepositoryUrl = ServerNetwork.SERVER_REPOSITORY_URL
	advertiser.public = _public


# Parse command line server name in the form of:
# --name xxxxx
static func get_name() -> String:
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
static func get_port() -> int:
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
static func get_public() -> bool:
	var public := false
	
	var args := OS.get_cmdline_args()
	for arg in args:
		if arg.nocasecmp_to("--public") == 0:
			public = true
			break
	
	return public


# Parse command line port in the form of:
# --nostats
static func get_no_stats() -> bool:
	var stats := false
	
	var args := OS.get_cmdline_args()
	for arg in args:
		if arg.nocasecmp_to("--nostats") == 0:
			stats = true
			break
	
	return stats and not OS.is_debug_build()


# Parse command line server name in the form of:
# --nolan
static func get_no_lan() -> bool:
	var no_lan := false
	
	var args := OS.get_cmdline_args()
	for arg in args:
		if arg.nocasecmp_to("--nolan") == 0:
			no_lan = true
			break
	
	return no_lan


# Parse command line server name in the form of:
# --fps
static func get_fps() -> bool:
	var fps := false
	
	var args := OS.get_cmdline_args()
	for arg in args:
		if arg.nocasecmp_to("--fps") == 0:
			fps = true
			break
	
	return fps
