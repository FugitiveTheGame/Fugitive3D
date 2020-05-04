extends Control

const MIN_NAME_LENGTH := 3

export(NodePath) var playerNamePath: NodePath
onready var playerNameInput := get_node(playerNamePath) as LineEdit

export(NodePath) var serverIpPath: NodePath
onready var serverIpInput := get_node(serverIpPath) as LineEdit

export(NodePath) var serverPortPath: NodePath
onready var serverPortInput := get_node(serverPortPath) as LineEdit

export(NodePath) var versionLabelPath: NodePath
onready var versionLabel := get_node(versionLabelPath) as Label

export (NodePath) var joiningDialogPath: NodePath
onready var joiningDialog := get_node(joiningDialogPath)

export (NodePath) var joinFailedDialogPath: NodePath
onready var joinFailedDialog := get_node(joinFailedDialogPath)


func _enter_tree():
	get_tree().connect("connected_to_server", self, "on_connected_to_server")
	get_tree().connect("connection_failed", self, "on_connection_failed")


func _exit_tree():
	get_tree().disconnect("connected_to_server", self, "on_connected_to_server")
	get_tree().disconnect("connection_failed", self, "on_connection_failed")
	
	joiningDialog.hide()
	
	UserData.data.user_name = playerNameInput.text
	UserData.data.last_ip = serverIpInput.text
	UserData.data.last_port = serverPortInput.text
	UserData.save_data()


func _ready():
	versionLabel.text = "v%d" % UserData.GAME_VERSION
	
	playerNameInput.text = UserData.data.user_name
	serverIpInput.text = UserData.data.last_ip
	serverPortInput.text = str(UserData.data.last_port)


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
	if ClientNetwork.join_game(serverIp, serverPort, playerName.strip_edges()):
		joiningDialog.show()
	else:
		joinFailedDialog.show()


func on_connected_to_server():
	vr.log_info("on_connected_to_server")
	go_to_lobby()


func on_connection_failed():
	joiningDialog.hide()
	joinFailedDialog.show()


func go_to_lobby():
	print("go_to_lobby() MUST BE OVERRIDEN")


func _on_ServerBrowser_connect_to_server(ip: String, port: int):
	on_connect_request(ip, port)


func on_connect_request(ip: String, port: int):
	var playerName := playerNameInput.text as String
	connect_to_server(playerName, ip, port)


func _on_ExitButton_pressed():
	print("Closing game")
	get_tree().quit()


func _on_CancelButton_pressed():
	ClientNetwork.reset_network()
	joinFailedDialog.hide()
