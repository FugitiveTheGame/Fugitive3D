extends Node

var socketUDP: PacketPeerUDP = null

var registerThread: Thread = null
var fetchThread: Thread = null

# Do any server specific setup here
# Then open a lobby and start listening for users
func _ready():
	# If we are going to be public, handle the initial registration
	if ServerUtils.get_public():
		# Third argument is optional userdata, it can be any variable.
		registerThread = Thread.new()
		registerThread.start(self, "run_register_publicly")
	# If we're not registering publicly, just continue
	else:
		go_to_lobby()


func go_to_lobby():
	get_tree().change_scene("res://server/lobby/ServerLobby.tscn")


func run_register_publicly(userdata):
	register_publicly()


func run_fetch_external_ip(advertiser):
	advertiser.fetch_external_ip()


func register_publicly():
	socketUDP = PacketPeerUDP.new()
	var listenPort := ServerUtils.get_port()
	
	if socketUDP.listen(listenPort) == OK:
		print("Repository regitration: listening on port: " + str(listenPort))
		
		var advertiser = ServerAdvertiser.new()
		advertiser.public = true
		advertiser.autoremove = false
		ServerUtils.configure_advertiser(advertiser, ServerUtils.get_name(), listenPort)
		add_child(advertiser)
		advertiser.connect("register_succeeded", self, "on_register_succeeded")
		advertiser.connect("register_failed", self, "on_register_failed")
		# This will get the IP, then proceed to register the server
		# As part of registration, the repository will connect to us on
		# UDP to confirm our ports are open
		fetchThread = Thread.new()
		fetchThread.start(self, "run_fetch_external_ip", advertiser)
		
		# Wait for the repository to ping us
		if socketUDP.wait() == OK:
			var array_bytes := socketUDP.get_packet()
			var message = array_bytes.get_string_from_ascii()
			if message == "ping":
				var ip := socketUDP.get_packet_ip()
				var port := socketUDP.get_packet_port()
				socketUDP.set_dest_address(ip, port)
				
				var response := "pong"
				# Send 3 response packets
				for ii in 3:
					socketUDP.put_packet(response.to_ascii())
				
				print("Port check request received. Response sent.")
			else:
				print("Public Repository Registration Failed: Bad message from Server Repository.")
				print("Do you have the latest version? Current Version: %d" % UserData.GAME_VERSION)
				get_tree().quit()
		else:
			print("Public Repository Registration Failed: No ping received from Repository.")
			print("Are your ports forwarded correctly? UDP & TCP Port: %d" % listenPort)
			get_tree().quit()
	else:
		print("Repository regitration: Error listening on port: " + str(listenPort))
		get_tree().quit()


func on_register_succeeded():
	print("Public Repository Registration Complete!")
	go_to_lobby()


func on_register_failed():
	get_tree().quit()


func _exit_tree():
	if socketUDP != null:
		socketUDP.close()
	
	if fetchThread != null:
		fetchThread.wait_to_finish()
	
	if registerThread != null:
		registerThread.wait_to_finish()
