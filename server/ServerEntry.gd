extends Node

var socketUDP: PacketPeerUDP = null


# Do any server specific setup here
# Then open a lobby and start listening for users
func _ready():
	# Now that we know we are a server, add our Reporter to the tree
	if not ServerUtils.get_no_stats():
		var serverReporter = load("res://server/reporter/ServerReporter.tscn").instantiate()
		get_tree().root.add_child.call_deferred(serverReporter)

	# If we are going to be public, handle the initial registration
	if ServerUtils.get_public():
		register_publicly()
	# If we're not registering publicly, just continue
	else:
		go_to_lobby()


func go_to_lobby():
	# Deferred: called both mid-_ready and from a registration signal
	get_tree().change_scene_to_file.call_deferred("res://server/lobby/ServerLobby.tscn")


# All of this stays on the main thread. The advertiser is a tree node whose
# HTTPRequest children only function once inside the tree, so neither add_child
# nor the IP fetch can run off-thread, and the repository's port check is
# answered by polling in _process rather than a blocking wait for the same
# reason.
func register_publicly():
	socketUDP = PacketPeerUDP.new()
	var listenPort := ServerUtils.get_port()

	# PacketPeerUDP.listen() was Godot 3; the 4.x name is bind(). Calling the
	# missing method returns null, which coerces to 0 and so compares equal to
	# OK, reporting a bound socket that was never listening.
	var bind_result := socketUDP.bind(listenPort)
	if bind_result != OK:
		print("Repository registration: Error binding port %d: %s" % [listenPort, error_string(bind_result)])
		get_tree().quit()
		return

	print("Repository registration: bound to port: " + str(listenPort))

	var advertiser := ServerAdvertiser.new()
	ServerUtils.configure_advertiser(advertiser, ServerUtils.get_server_name(), listenPort, ServerUtils.get_public(), false)
	add_child(advertiser)
	advertiser.register_succeeded.connect(on_register_succeeded)
	advertiser.register_failed.connect(on_register_failed)
	# This gets the external IP, then proceeds to register the server. As part
	# of that registration the repository sends a UDP ping to confirm the port
	# is really reachable, which answer_port_check replies to.
	advertiser.fetch_external_ip()


func _process(_delta):
	answer_port_check()


func answer_port_check():
	if socketUDP == null:
		return

	while socketUDP.get_available_packet_count() > 0:
		var message := socketUDP.get_packet().get_string_from_ascii()
		if message != "ping":
			print("Repository port check: bad message from Server Repository: '%s'" % message)
			print("Do you have the latest version? Current Version: %d" % UserData.GAME_VERSION)
			continue

		socketUDP.set_dest_address(socketUDP.get_packet_ip(), socketUDP.get_packet_port())

		# Send redundant response packets
		var response := "pong".to_ascii_buffer()
		for ii in 10:
			socketUDP.put_packet(response)

		print("Port check request received. Response sent.")


func on_register_succeeded():
	print("Public Repository Registration Complete!")
	go_to_lobby()


func on_register_failed():
	print("Public Repository Registration Failure. Exiting.")
	if socketUDP != null:
		socketUDP.close()

	get_tree().quit()


func _exit_tree():
	if socketUDP != null:
		socketUDP.close()
