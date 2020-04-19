extends Control


func _enter_tree():
	get_tree().connect("connected_to_server", self, "on_connected_to_server")


func _exit_tree():
	get_tree().disconnect("connected_to_server", self, "on_connected_to_server")


func _on_ConnectButton_pressed():
	var ip := $ServerIpLabel/ServerIp.text as String
	var portStr := $ServerPortLabel/ServerPort.text as String
	var port := int(portStr)
	
	on_connect_request(ip, port)


func connect_to_server(playerName: String, serverIp: String, serverPort: int):
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
	var playerName := $PlayerNameLabel/PlayerName.text as String
	connect_to_server(playerName, ip, port)
