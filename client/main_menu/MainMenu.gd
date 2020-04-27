extends Control

const MIN_NAME_LENGTH := 3

export(NodePath) var playerNamePath: NodePath
onready var playerNameInput := get_node(playerNamePath) as LineEdit

export(NodePath) var serverIpPath: NodePath
onready var serverIpInput := get_node(serverIpPath) as LineEdit

export(NodePath) var serverPortPath: NodePath
onready var serverPortInput := get_node(serverPortPath) as LineEdit


func _enter_tree():
	get_tree().connect("connected_to_server", self, "on_connected_to_server")


func _exit_tree():
	get_tree().disconnect("connected_to_server", self, "on_connected_to_server")
	
	UserData.data.user_name = playerNameInput.text
	UserData.data.last_ip = serverIpInput.text
	UserData.data.last_port = serverPortInput.text
	UserData.save_data()


func _ready():
	playerNameInput.text = UserData.data.user_name
	serverIpInput.text = UserData.data.last_ip
	serverPortInput.text = str(UserData.data.last_port)
	
	var args := OS.get_cmdline_args()
	print("Command Line args: %d" % [args.size()])
	if (args.size() > 0):
		for arg in args:
			print("    : %s" % arg)
			var keyValuePair = arg.split("=")
			
			match keyValuePair[0]:
				"--name":
					playerNameInput.text = keyValuePair[1]
					# Also override the default file save path so each test user has its own settings.
					UserData.file_name = 'user://user_data-%s.json' % playerNameInput.text
				"--ip":
					serverIpInput.text = keyValuePair[1]
				_:
					print("UNKNOWN ARGUMENT %s" % keyValuePair[0])
	
	if (args.size() > 0):
		connect_to_server(playerNameInput.text, serverIpInput.text, int(serverPortInput.text))


func _on_ConnectButton_pressed():
	var ip := serverIpInput.text as String
	var portStr := serverPortInput.text as String
	var port := int(portStr)
	
	on_connect_request(ip, port)


func connect_to_server(playerName: String, serverIp: String, serverPort: int):
	if playerName.strip_edges().length() < MIN_NAME_LENGTH:
		$UserNameErrorDialog.popup_centered()
		
		return
	
	vr.log_info("connect_to_server")
	ClientNetwork.join_game(serverIp, serverPort, playerName.strip_edges())


func on_connected_to_server():
	vr.log_info("on_connected_to_server")
	go_to_lobby()


func go_to_lobby():
	print("go_to_lobby() MUST BE OVERRIDEN")


func _on_ServerBrowser_connect_to_server(ip, port):
	on_connect_request(ip, int(port))


func on_connect_request(ip: String, port: int):
	var playerName := playerNameInput.text as String
	connect_to_server(playerName, ip, port)
