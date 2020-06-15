extends Node
class_name ServerAdvertiser, 'res://addons/LANServerBroadcast/server_advertiser/ServerAdvertiser.png'

signal register_failed
signal register_succeeded

const DEFAULT_PORT := 32000
const REPOSITORY_ADVERTISE_INTERVAL := 30.0

const SERVER_ID_FORMAT := "%s:%d"

# How often to broadcast out to the network that this host is active
export (float) var broadcast_interval: float = 1.0
var serverInfo := {"name": "LAN Game", "port": 0}

var socketUDP: PacketPeerUDP
var broadcastTimer := Timer.new()
var broadcastPort := DEFAULT_PORT
var externalIp = null
var serverRepositoryUrl: String
var public := false

var ipRequest := HTTPRequest.new()
var registerRequest := HTTPRequest.new()
var removeRequest := HTTPRequest.new()

var repositoryRegisterTimer := Timer.new()
var initial_registration := true


func _ready():
	add_child(broadcastTimer)
	broadcastTimer.connect("timeout", self, "broadcast") 
	broadcastTimer.wait_time = broadcast_interval
	broadcastTimer.one_shot = false
	
	add_child(ipRequest)
	ipRequest.connect("request_completed", self, "_on_IpRequest_request_completed")
	
	add_child(registerRequest)
	registerRequest.connect("request_completed", self, "_on_RegisterRequest_request_completed")
	
	add_child(removeRequest)


func start_advertising_lan():
	print("Starting LAN broadcast")
	broadcastTimer.start()
	
	socketUDP = PacketPeerUDP.new()
	socketUDP.set_broadcast_enabled(true)
	socketUDP.set_dest_address('255.255.255.255', broadcastPort)


# By default we only advertise on LAN
# Calling this will start advertising on WAN
func start_advertising_publicly():
	public = true
	
	if externalIp == null:
		fetch_external_ip()
	else:
		register_server()
	
	# Setup the heat beat
	repositoryRegisterTimer.wait_time = REPOSITORY_ADVERTISE_INTERVAL
	add_child(repositoryRegisterTimer)
	repositoryRegisterTimer.connect("timeout", self, "_on_RepositoryRegisterTimer_timeout")
	repositoryRegisterTimer.start()


func broadcast():
	#print('Broadcasting game...')
	var packetMessage := to_json(serverInfo)
	var packet := packetMessage.to_ascii()
	socketUDP.put_packet(packet)


func _exit_tree():
	broadcastTimer.stop()
	if socketUDP != null:
		socketUDP.close()


func fetch_external_ip():
	var endpointUrl := serverRepositoryUrl + "/reflection/ip"
	print("fetch_external_ip")
	ipRequest.request(endpointUrl)


func _on_IpRequest_request_completed(result, response_code, headers, body):
	if response_code >= 200 and response_code < 300:
		var json = parse_json(body.get_string_from_utf8())
		print('External IP: %s' % json.ip)
		externalIp = json.ip
		serverInfo["ip"] = externalIp
		
		if public:
			register_server()
	else:
		print('Failed to get external IP')


func register_server():
	if externalIp != null:
		var serverID := SERVER_ID_FORMAT % [serverInfo["ip"], serverInfo["port"]]
		var url := serverRepositoryUrl + "/servers/" + serverID
		
		var body := JSON.print(serverInfo)
		var headers := ["Content-Type: application/json"]
		if initial_registration:
			print("initial registration")
			registerRequest.request(url, headers, false, HTTPClient.METHOD_POST, body)
		else:
			#print("updating registration")
			registerRequest.request(url, headers, false, HTTPClient.METHOD_PUT, body)


func _on_RegisterRequest_request_completed(result, response_code, headers, body):
	if response_code >= 200 and response_code < 300:
		initial_registration = false
		emit_signal("register_succeeded")
	else:
		var message := body.get_string_from_utf8() as String
		print("Server registration failed with code: %d and message: %s" % [response_code, message])
		emit_signal("register_failed")


func _on_RepositoryRegisterTimer_timeout():
	register_server()


func remove_from_repository():
	if public:
		var serverID := SERVER_ID_FORMAT % [serverInfo["ip"], serverInfo["port"]]
		var url := serverRepositoryUrl + "/servers/" + serverID
		
		removeRequest.request(url, [], false, HTTPClient.METHOD_DELETE)
