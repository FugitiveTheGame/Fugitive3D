extends Node
class_name ServerAdvertiser, 'res://addons/LANServerBroadcast/server_advertiser/ServerAdvertiser.png'

signal register_failed
signal register_succeeded

const DEFAULT_PORT := 32000
const REPOSITORY_ADVERTISE_INTERVAL := 30_000

const SERVER_ID_FORMAT := "%s:%d"

# How often to broadcast out to the network that this host is active
export (float) var broadcast_interval: float = 1.0
var serverInfo := {
	"name": "LAN Game",
	"port": 0,
	"max_players": 10,
	"current_players": 0
	}

var socketUDP: PacketPeerUDP
var broadcastTimer := Timer.new()
var broadcastPort := DEFAULT_PORT
var serverRepositoryUrl: String
var public := false

var ipRequest := HTTPRequest.new()
var registerRequest := HTTPRequest.new()
var removeRequest := HTTPRequest.new()

var repositoryRegisterTimer := Threshold.new(REPOSITORY_ADVERTISE_INTERVAL)
var initial_registration := true

func _init():
	ipRequest.connect("request_completed", self, "_on_IpRequest_request_completed")
	add_child(ipRequest)
	
	registerRequest.connect("request_completed", self, "_on_RegisterRequest_request_completed")
	add_child(registerRequest)
	
	add_child(removeRequest)


func _ready():
	broadcastTimer.name = "BroadcastTimer"
	broadcastTimer.wait_time = broadcast_interval
	broadcastTimer.one_shot = false
	broadcastTimer.connect("timeout", self, "broadcast") 
	add_child(broadcastTimer)


func _process(delta):
	if repositoryRegisterTimer.is_exceeded():
		_on_RepositoryRegisterTimer_timeout()


func update_players(num_players: int):
	serverInfo["current_players"] = num_players


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
	
	if ServerAdvertiserData.externalIp == null:
		fetch_external_ip()
	else:
		register_server()
	
	# Start the heat beat
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
	
	if not ipRequest.is_inside_tree():
		print("Error: ipRequest NOT INSIDE TREE")
		return
	
	ipRequest.cancel_request()
	ipRequest.request(endpointUrl)


func _on_IpRequest_request_completed(result, response_code, headers, body):
	if response_code >= 200 and response_code < 300:
		var json = parse_json(body.get_string_from_utf8())
		
		ServerAdvertiserData.externalIp = json.ip
		serverInfo["ip"] = ServerAdvertiserData.externalIp
		
		print('External IP: %s' % ServerAdvertiserData.externalIp)
		
		if public:
			register_server()
	else:
		print('Failed to get external IP')


func register_server():
	if ServerAdvertiserData.externalIp != null:
		var serverID := SERVER_ID_FORMAT % [serverInfo["ip"], serverInfo["port"]]
		var url := serverRepositoryUrl + "/servers/" + serverID
		
		var body := JSON.print(serverInfo)
		var headers := ["Content-Type: application/json"]
		
		if not registerRequest.is_inside_tree():
			print("Error: registerRequest NOT INSIDE TREE")
			return
		
		registerRequest.cancel_request()
		if initial_registration:
			print("initial registration")
			registerRequest.request(url, headers, false, HTTPClient.METHOD_POST, body)
		else:
			print("updating registration")
			registerRequest.request(url, headers, false, HTTPClient.METHOD_PUT, body)
	else:
		fetch_external_ip()


func _on_RegisterRequest_request_completed(result, response_code, headers, body):
	print("RegisterRequest Status: %d" % response_code)
	if response_code >= 200 and response_code < 300:
		initial_registration = false
		emit_signal("register_succeeded")
	else:
		var message := body.get_string_from_utf8() as String
		print("Server registration failed with code: %d and message: %s" % [response_code, message])
		print(ServerAdvertiserData.externalIp)
		emit_signal("register_failed")


func _on_RepositoryRegisterTimer_timeout():
	print("RepositoryRegister Timer %d" % OS.get_unix_time())
	register_server()


func remove_from_repository():
	if public:
		var serverID := SERVER_ID_FORMAT % [serverInfo["ip"], serverInfo["port"]]
		var url := serverRepositoryUrl + "/servers/" + serverID
		
		removeRequest.cancel_request()
		removeRequest.request(url, [], false, HTTPClient.METHOD_DELETE)
