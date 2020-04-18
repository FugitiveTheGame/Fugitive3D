extends Panel

signal connect_to_server(ip, port)

export (NodePath) var serverListPath: NodePath
onready var serverList := get_node(serverListPath)

var serverListItemScene := preload("res://client/main_menu/server_browser/ServerListItem.tscn")


func _on_ServerListener_new_server(serverInfo):
	var serverNode := serverListItemScene.instance()
	serverNode.populate(serverInfo, true)
	serverNode.connect("connect_to_server", self, "on_connect_request")
	serverList.add_child(serverNode)


func _on_ServerListener_remove_server(serverIp):
	for serverNode in serverList.get_children():
		if serverNode.serverInfo.ip == serverIp:
			serverList.remove_child(serverNode)
			break

# Just re-emit
func on_connect_request(ip: String, port: int):
	emit_signal("connect_to_server", ip, port)
