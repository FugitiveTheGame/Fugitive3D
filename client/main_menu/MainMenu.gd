extends Control


func _ready():
	get_tree().connect("connected_to_server", self, "on_connected_to_server")


func _on_ConnectButton_pressed():
	var ip := $ServerIpLabel/ServerIp.text as String
	var portStr := $ServerPortLabel/ServerPort.text as String
	var port := int(portStr)
	var playerName := $PlayerNameLabel/PlayerName.text as String
	connect_to_server(playerName, ip, port)


func connect_to_server(playerName: String, serverIp: String, serverPort: int):
	vr.log_info("connect_to_server")
	ClientNetwork.join_game(serverIp, serverPort, playerName)


func on_connected_to_server():
	vr.log_info("on_connected_to_server")
	go_to_lobby()


func go_to_lobby():
	print("go_to_lobby() MUST BE OVERRIDEN")

