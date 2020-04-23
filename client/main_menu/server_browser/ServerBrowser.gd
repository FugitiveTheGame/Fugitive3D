extends PanelContainer

signal connect_to_server(ip, port)

export (NodePath) var serverListPath: NodePath
onready var serverList := get_node(serverListPath)

var serverListItemScene := preload("res://client/main_menu/server_browser/ServerListItem.tscn")


func _ready():
	$ServerListener.serverRepositoryUrl = ServerNetwork.SERVER_REPOSITORY_URL + "/list"
	$ServerListener.request_servers()


func _on_ServerListener_new_server(serverInfo):
	add_server(serverInfo)


func _on_ServerListener_remove_server(serverIp):
	remove_server(serverIp)


func add_server(serverInfo):
	var serverNode := serverListItemScene.instance()
	serverNode.populate(serverInfo)
	serverNode.connect("connect_to_server", self, "on_connect_request")
	serverList.add_child(serverNode)


func remove_server(serverIp):
	for serverNode in serverList.get_children():
		if serverNode.serverInfo.ip == serverIp:
			serverList.remove_child(serverNode)
			break


func get_server(serverIp) -> Control:
	var node = null
	for serverNode in serverList.get_children():
		if serverNode.serverInfo.ip == serverIp:
			node = serverNode
			break
	
	return node


# Just re-emit
func on_connect_request(ip, port):
	emit_signal("connect_to_server", ip, port)


func _on_RefreshButton_pressed():
	$ServerListener.request_servers()


func _on_ServerListener_update_server(serverInfo):
	var serverNode := get_server(serverInfo.ip)
	serverNode.populate(serverInfo)
