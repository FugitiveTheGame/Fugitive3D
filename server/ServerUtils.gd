extends Object
class_name ServerUtils


static func configure_advertiser(advertiser: ServerAdvertiser, _name, _port):
	advertiser.serverInfo["port"] = _port
	advertiser.serverInfo["name"] = _name
	advertiser.serverInfo["game_version"] = UserData.GAME_VERSION
	advertiser.serverRepositoryUrl = ServerNetwork.SERVER_REPOSITORY_URL


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
