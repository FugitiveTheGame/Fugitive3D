extends Panel

signal connect_to_server(ip, port)

export (NodePath) var serverListPath: NodePath
onready var serverList := get_node(serverListPath)

var serverListItemScene := preload("res://client/main_menu/server_browser/ServerListItem.tscn")


func _ready():
	request_servers()


func request_servers():
	var url := ServerNetwork.SERVER_REPOSITORY_URL + "/list"
	$ServerRepoRequest.request(url)


func _on_ServerRepoRequest_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var servers = parse_json(body.get_string_from_utf8())
		
		if servers != null:
			for server in servers:
				add_server(server, false)
		
	else:
		print('Failed to get servers')


func _on_ServerListener_new_server(serverInfo):
	add_server(serverInfo, true)


func _on_ServerListener_remove_server(serverIp):
	remove_server(serverIp)


func add_server(serverInfo, is_lan):
	# If the server already exists, remove it
	remove_server(serverInfo.ip)
	
	var serverNode := serverListItemScene.instance()
	serverNode.populate(serverInfo, is_lan)
	serverNode.connect("connect_to_server", self, "on_connect_request")
	serverList.add_child(serverNode)


func remove_server(serverIp):
	for serverNode in serverList.get_children():
		if serverNode.serverInfo.ip == serverIp:
			serverList.remove_child(serverNode)
			break


# Just re-emit
func on_connect_request(ip, port):
	emit_signal("connect_to_server", ip, port)


func _on_RefreshButton_pressed():
	request_servers()
