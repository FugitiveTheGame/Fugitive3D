extends Node
class_name ServerAdvertiser, 'res://addons/LANServerBroadcast/server_advertiser/ServerAdvertiser.png'

const DEFAULT_PORT := 32000

# How often to broadcast out to the network that this host is active
export (float) var broadcast_interval: float = 1.0
var serverInfo := {"name": "LAN Game", "port": 0}

var socketUDP: PacketPeerUDP
var broadcastTimer := Timer.new()
var broadcastPort := DEFAULT_PORT
var externalIp = null
var private := false
var serverRepositoryUrl: String

var ipRequest := HTTPRequest.new()
var registerRequest := HTTPRequest.new()

var repositoryRegisterTimer := Timer.new()

func _ready():
	broadcastTimer.wait_time = broadcast_interval
	broadcastTimer.one_shot = false
	broadcastTimer.autostart = true
	
	add_child(ipRequest)
	ipRequest.connect("request_completed", self, "_on_IpRequest_request_completed")
	
	add_child(registerRequest)
	
	if get_tree().is_network_server():
		add_child(broadcastTimer)
		broadcastTimer.connect("timeout", self, "broadcast") 
		
		socketUDP = PacketPeerUDP.new()
		socketUDP.set_broadcast_enabled(true)
		socketUDP.set_dest_address('255.255.255.255', broadcastPort)
		
		# If private, don't advertise to the repository
		if not private:
			repositoryRegisterTimer.wait_time = 30.0
			add_child(repositoryRegisterTimer)
			repositoryRegisterTimer.connect("timeout", self, "_on_RepositoryRegisterTimer_timeout")
			repositoryRegisterTimer.start()
		
		fetch_external_ip()


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
	ipRequest.request("https://api.ipify.org/?format=json")


func _on_IpRequest_request_completed(result, response_code, headers, body):
	if response_code == 200:
		var json = parse_json(body.get_string_from_utf8())
		print('External IP: %s' % json.ip)
		externalIp = json.ip
		serverInfo["ip"] = externalIp
		
		register_server()
	else:
		print('Failed to get external IP')


func register_server():
	if externalIp != null:
		var url := serverRepositoryUrl
		
		# Marshal the data for transmission
		# They must all be strings
		var data = {
			"ip": serverInfo["ip"],
			"port": str(serverInfo["port"]),
			"name": serverInfo["name"],
		}
		
		var body := JSON.print(data)
		var headers := ["Content-Type: application/json"]
		registerRequest.request(url, headers, false, HTTPClient.METHOD_POST, body)


func _on_RepositoryRegisterTimer_timeout():
	register_server()
