extends Control

export(NodePath) var playerNamePath: NodePath
onready var playerNameInput := get_node(playerNamePath) as LineEdit

export(NodePath) var serverIpPath: NodePath
onready var serverIp := get_node(serverIpPath) as LineEdit

export(NodePath) var serverPortPath: NodePath
onready var serverPort := get_node(serverPortPath) as LineEdit


func _enter_tree():
	get_tree().connect("connected_to_server", self, "on_connected_to_server")


func _exit_tree():
	get_tree().disconnect("connected_to_server", self, "on_connected_to_server")
	
	UserData.data.user_name = playerNameInput.text
	UserData.data.last_ip = serverIp.text
	UserData.data.last_port = serverPort.text
	UserData.save_data()


func _ready():
	playerNameInput.text = UserData.data.user_name
	serverIp.text = UserData.data.last_ip
	serverPort.text = str(UserData.data.last_port)


func _on_ConnectButton_pressed():
	var ip := serverIp.text as String
	var portStr := serverPort.text as String
	var port := int(portStr)
	
	on_connect_request(ip, port)


func connect_to_server(playerName: String, serverIp: String, serverPort: int):
	if playerName.strip_edges().length() > 0:
		vr.log_info("connect_to_server")
		ClientNetwork.join_game(serverIp, serverPort, playerName)


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
