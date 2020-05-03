extends Node

# Go to the proper entry for this client
func _ready():
	var clientType := PlatformTypeUtils.get_platform_type()
	
	match clientType:
		PlatformTypeUtils.PlatformType.FlatDesktop:
			print("Client is Flat")
			go_to_flat()
		PlatformTypeUtils.PlatformType.FlatMobile:
			print("Client is Flat Mobile")
			go_to_flat()
		PlatformTypeUtils.PlatformType.VrDesktop:
			print("Client is PC VR")
			go_to_pc_vr()
		PlatformTypeUtils.PlatformType.VrMobile:
			print("Client is Mobile VR")
			go_to_mobile_vr()

func handle_commandline_args():
	var playerName = UserData.data.user_name
	var serverIp = UserData.data.last_ip
	var serverPort = int(UserData.data.last_port)
	
	var args := OS.get_cmdline_args()
	print("Command Line args: %d" % [args.size()])
	if (args.size() > 0):
		for arg in args:
			print("    : %s" % arg)
			var keyValuePair = arg.split("=")
			
			match keyValuePair[0]:
				"--name":
					playerName = keyValuePair[1]
					# Also override the default file save path so each test user has its own settings.
					UserData.file_name = 'user://user_data-%s.json' % playerName
				"--ip":
					serverIp = keyValuePair[1]
				_:
					print("UNKNOWN ARGUMENT %s" % keyValuePair[0])
		ClientNetwork.join_game(serverIp, serverPort, playerName.strip_edges())


func go_to_flat():
	# Handle desktop window settings
	if not OS.has_feature("mobile"):
		var fullscreen = UserData.data.full_screen
		if fullscreen != OS.window_fullscreen:
			OS.window_fullscreen = fullscreen
	
	get_tree().change_scene("res://client/main_menu/flat/FlatMainMenu.tscn")
	
	# Note that this one time handling of command line arguments is intentionally
	# happening after the MainMenu for a given client is initialized: those scenes have
	# handlers for join that need to be ready in order for the game to process the join command
	# correctly.
	handle_commandline_args()


func go_to_pc_vr():
	prepare_pc_vr()
	
	vr.switch_scene("res://client/main_menu/vr/VrClientMainMenu.tscn")


func go_to_mobile_vr():
	prepare_mobile_vr()
	
	vr.switch_scene("res://client/main_menu/vr/VrClientMainMenu.tscn")


func prepare_pc_vr():
	vr.initialize()


func prepare_mobile_vr():
	print("Configuring for Mobile VR")
	
	vr.initialize()
	
	var ovrPerformance = preload("res://addons/godot_ovrmobile/OvrPerformance.gdns").new()
	
	# enable the extra latency mode: this gives some performance headroom at the cost
	# of one more frame of latency
	ovrPerformance.set_extra_latency_mode(1)
	
	# set fixed foveation level
	# for details see https://developer.oculus.com/documentation/quest/latest/concepts/mobile-ffr/
	ovrPerformance.set_foveation_level(4)
	
	# This will dynamically change the foveation level up to the previous level
	ovrPerformance.set_enable_dynamic_foveation(true)
	
	#var ovr_vr_api_proxy = preload("res://addons/godot_ovrmobile/OvrVrApiProxy.gdns").new();
	#var ovr_types = preload("res://addons/godot_ovrmobile/OvrVrApiTypes.gd").new();
	
	#print("  vrapi_get_property_int(VRAPI_FOVEATION_LEVEL) = ", ovr_vr_api_proxy.vrapi_get_property_int(ovr_types.OvrProperty.VRAPI_FOVEATION_LEVEL));
	
