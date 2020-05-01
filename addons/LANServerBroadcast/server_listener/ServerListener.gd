extends Node
class_name ServerListener, 'res://addons/LANServerBroadcast/server_listener/ServerListener.png'

signal new_server
signal update_server
signal remove_server

const REPOSITORY_REFRESH_INTERVAL := 10.0

var cleanUpTimer := Timer.new()
var socketUDP := PacketPeerUDP.new()
var listenPort := ServerAdvertiser.DEFAULT_PORT
var serverRepositoryUrl: String
var knownServers = {}

var serverRepoRequestTimer := Timer.new()
var serverRepoRequest := HTTPRequest.new()


# Number of seconds to wait when a server hasn't been heard from
# before calling remove_server
export (int) var server_cleanup_threshold_lan: int = 3
export (int) var server_cleanup_threshold_wan: int = 15

func _init():
	cleanUpTimer.wait_time = server_cleanup_threshold_lan
	cleanUpTimer.one_shot = false
	cleanUpTimer.autostart = true
	cleanUpTimer.connect("timeout", self, 'clean_up')
	add_child(cleanUpTimer)

func _ready():
	knownServers.clear()
	
	serverRepoRequestTimer.wait_time = REPOSITORY_REFRESH_INTERVAL
	serverRepoRequestTimer.one_shot = false
	add_child(serverRepoRequestTimer)
	serverRepoRequestTimer.connect("timeout", self, "request_servers")
	serverRepoRequestTimer.start()
	
	
	add_child(serverRepoRequest)
	serverRepoRequest.connect("request_completed", self, "_on_ServerRepoRequest_request_completed")
	
	if socketUDP.listen(listenPort) != OK:
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
			var gameInfo = parse_json(serverMessage)
			gameInfo.ip = serverIp
			gameInfo.lan = true
			
			add_server(gameInfo)


func add_server(serverInfo):
	serverInfo.lastSeen = OS.get_unix_time()
	
	# We've discovered a new server! Add it to the list and let people know
	if not knownServers.has(serverInfo.ip):
		knownServers[serverInfo.ip] = serverInfo
		print("New server found: %s - %s:%s" % [serverInfo.name, serverInfo.ip, serverInfo.port])
		emit_signal("new_server", serverInfo)
	# Update the last seen time
	else:
		knownServers[serverInfo.ip] = serverInfo
		emit_signal("update_server", serverInfo)


func clean_up():
	var now = OS.get_unix_time()
	for serverIp in knownServers:
		var serverInfo = knownServers[serverIp]
		
		var threshold: float
		if serverInfo.lan:
			threshold = server_cleanup_threshold_lan
		else:
			threshold = server_cleanup_threshold_wan
		
		if (now - serverInfo.lastSeen) > threshold:
			knownServers.erase(serverIp)
			print('Remove old server: %s' % serverIp)
			emit_signal("remove_server", serverIp)


func _exit_tree():
	socketUDP.close()


func request_servers():
	var endpointUrl = serverRepositoryUrl + "/servers"
	serverRepoRequest.request(endpointUrl)


func _on_ServerRepoRequest_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var servers = parse_json(body.get_string_from_utf8())
		
		if servers != null:
			for server in servers:
				server.lan = false
				add_server(server)
	else:
		print('Failed to get servers')
