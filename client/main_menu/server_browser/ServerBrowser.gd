extends PanelContainer

signal connect_to_server(ip, port)

@export var serverListPath: NodePath
@onready var serverList := get_node(serverListPath)

var serverListItemScene := preload("res://client/main_menu/server_browser/ServerListItem.tscn")


const STATUS_COLOR_CONNECTING := Color(1, 0.85, 0.1)
const STATUS_COLOR_CONNECTED := Color(0.2, 0.8, 0.2)
const STATUS_COLOR_FAILED := Color(0.9, 0.2, 0.2)

@onready var connectionStatusIndicator: Panel = $VBoxContainer/HBoxContainer/ConnectionStatusIndicator


func _ready():
	$ServerListener.serverRepositoryUrl = ServerNetwork.SERVER_REPOSITORY_URL
	set_connection_status(STATUS_COLOR_CONNECTING, "Connecting to server list...")
	$ServerListener.call_deferred("request_servers")


func set_connection_status(color: Color, tooltip: String):
	connectionStatusIndicator.modulate = color
	connectionStatusIndicator.tooltip_text = tooltip


func _on_ServerListener_repo_connecting():
	set_connection_status(STATUS_COLOR_CONNECTING, "Connecting to server list...")


func _on_ServerListener_repo_connected():
	set_connection_status(STATUS_COLOR_CONNECTED, "Connected to server list")


func _on_ServerListener_repo_connection_failed():
	set_connection_status(STATUS_COLOR_FAILED, "Failed to connect to server list")


func _on_ServerListener_new_server(serverInfo):
	add_server(serverInfo)


func _on_ServerListener_remove_server(serverIp: String, serverPort: int):
	remove_server(serverIp, serverPort)


func add_server(serverInfo):
	if not serverInfo.has("game_version") or (int(serverInfo.game_version)) != UserData.GAME_VERSION:
		print("Warning: Server is wrong version, throwing it away")
	else:
		print("add_server: " + serverInfo.name + " port " + str(serverInfo.port))
		var serverNode := serverListItemScene.instantiate()
		serverNode.populate(serverInfo)
		serverNode.connect("connect_to_server", Callable(self, "on_connect_request"))
		serverList.add_child(serverNode)


func remove_server(serverIp: String, port: int):
	print("remove_server: " + serverIp)
	for serverNode in serverList.get_children():
		if serverNode.serverInfo.ip == serverIp and serverNode.serverInfo.port == port:
			serverNode.disconnect("connect_to_server", Callable(self, "on_connect_request"))
			serverNode.queue_free()
			break


func get_server(serverIp, serverPort) -> Control:
	var node = null
	for serverNode in serverList.get_children():
		if serverNode.serverInfo.ip == serverIp and serverNode.serverInfo.port == serverPort:
			node = serverNode
			break
	
	return node


# Just re-emit
func on_connect_request(ip: String, port: int):
	emit_signal("connect_to_server", ip, port)


func _on_RefreshButton_pressed():
	GameAnalytics.design_event("server_browser_manual_refresh")
	$ServerListener.request_servers()


func _on_ServerListener_update_server(serverInfo):
	var serverNode := get_server(serverInfo.ip, serverInfo.port)
	if serverNode != null:
		serverNode.populate(serverInfo)
