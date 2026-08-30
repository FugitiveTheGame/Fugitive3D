@icon('res://addons/LANServerBroadcast/server_listener/ServerListener.png')
extends Node
class_name ServerListener

signal new_server
signal update_server
signal remove_server

const REPOSITORY_REFRESH_INTERVAL := 5.0

var cleanUpTimer := Timer.new()
var socketUDP := PacketPeerUDP.new()
var listenPort := ServerAdvertiser.DEFAULT_PORT
var serverRepositoryUrl: String
var knownServers = {}

var serverRepoRequestTimer := Timer.new()
var serverRepoRequest := HTTPRequest.new()


# Number of seconds to wait when a server hasn't been heard from
# before calling remove_server
@export var server_cleanup_threshold_lan: int = 3
@export var server_cleanup_threshold_wan: int = 15

func get_server_id(ip, port) -> String:
	return str(ip) + ":" + str(port)

func _init():
	cleanUpTimer.name = "CleanUpTimer"
	cleanUpTimer.wait_time = server_cleanup_threshold_lan
	cleanUpTimer.one_shot = false
	cleanUpTimer.autostart = true
	cleanUpTimer.connect("timeout", Callable(self, 'clean_up'))
	add_child(cleanUpTimer)
	# Parent the helper nodes here as well, so a listener that is freed
	# before entering the tree does not leak them
	add_child(serverRepoRequestTimer)
	add_child(serverRepoRequest)

func _ready():
	knownServers.clear()

	serverRepoRequestTimer.wait_time = REPOSITORY_REFRESH_INTERVAL
	serverRepoRequestTimer.one_shot = false
	serverRepoRequestTimer.connect("timeout", Callable(self, "request_servers"))
	serverRepoRequestTimer.start()

	serverRepoRequest.connect("request_completed", Callable(self, "_on_ServerRepoRequest_request_completed"))
	
	if socketUDP.bind(listenPort) != OK:
		print("GameServer LAN service: Error listening on port: " + str(listenPort))
	else:
		print("GameServer LAN service: Listening on port: " + str(listenPort))


func _process(delta):
	if socketUDP.get_available_packet_count() > 0:
		var serverIp = socketUDP.get_packet_ip()
		var serverPort = socketUDP.get_packet_port()
		var array_bytes = socketUDP.get_packet()
		
		if serverIp != '' and serverPort > 0:
			var serverMessage = array_bytes.get_string_from_ascii()
			var test_json_conv = JSON.new()
			test_json_conv.parse(serverMessage)
			var gameInfo = test_json_conv.get_data()
			gameInfo.ip = serverIp
			gameInfo.lan = true
			
			add_server(gameInfo)


func add_server(serverInfo):
	serverInfo.lastSeen = Time.get_unix_time_from_system()
	
	# We've discovered a new server! Add it to the list and let people know
	var serverId = get_server_id(serverInfo.ip, serverInfo.port)
	if not knownServers.has(serverId):
		knownServers[serverId] = serverInfo
		print("New server found: %s - %s:%s" % [serverInfo.name, serverInfo.ip, serverInfo.port])
		emit_signal("new_server", serverInfo)
	# Update the last seen time
	else:
		knownServers[serverId] = serverInfo
		emit_signal("update_server", serverInfo)


func clean_up():
	var now = Time.get_unix_time_from_system()
	for serverId in knownServers:
		var serverInfo = knownServers[serverId]
		
		var threshold: float
		if serverInfo.lan:
			threshold = server_cleanup_threshold_lan
		else:
			threshold = server_cleanup_threshold_wan
		
		if (now - serverInfo.lastSeen) > threshold:
			knownServers.erase(serverId)
			print('Remove old server: %s' % serverId)
			emit_signal("remove_server", serverInfo.ip, serverInfo.port)


func _exit_tree():
	socketUDP.close()


func request_servers():
	serverRepoRequest.cancel_request()
	
	var endpointUrl = serverRepositoryUrl + "/servers"
	serverRepoRequest.request(endpointUrl)


func _on_ServerRepoRequest_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var test_json_conv = JSON.new()
		test_json_conv.parse(body.get_string_from_utf8())
		var servers = test_json_conv.get_data()
		
		if servers != null:
			for server in servers:
				server.lan = false
				add_server(server)
	else:
		print('Failed to get servers')
