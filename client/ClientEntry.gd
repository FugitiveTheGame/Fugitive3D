extends Node

# Go to the proper entry for this client
func _ready():
	init_analytics()
	
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
	get_tree().change_scene("res://client/main_menu/flat/FlatMainMenu.tscn")
	
	# Note that this one time handling of command line arguments is intentionally
	# happening after the MainMenu for a given client is initialized: those scenes have
	# handlers for join that need to be ready in order for the game to process the join command
	# correctly.
	handle_commandline_args()


func prepare_vr_common():
	# Joypad mappings overlap w\ vr button inputs,
	# we need to remove them for vr clients
	for action in InputMap.get_actions():
		for action_event in InputMap.get_action_list(action):
			if action_event is InputEventJoypadButton:
				InputMap.action_erase_event(action, action_event)


func go_to_pc_vr():
	prepare_pc_vr()
	
	vr.switch_scene("res://client/main_menu/vr/VrClientMainMenu.tscn")


func go_to_mobile_vr():
	prepare_mobile_vr()
	
	vr.switch_scene("res://client/main_menu/vr/VrClientMainMenu.tscn")


func prepare_pc_vr():
	prepare_vr_common()
	vr.initialize()


func prepare_mobile_vr():
	print("Configuring for Mobile VR")
	prepare_vr_common()
	vr.initialize()
	
	# enable the extra latency mode: this gives some performance headroom at the cost
	# of one more frame of latency
	vr.set_extra_latency_mode(1)
	
	# set fixed foveation level
	# for details see https://developer.oculus.com/documentation/quest/latest/concepts/mobile-ffr/
	vr.set_foveation_level(vr.FoveatedRenderingLevel.Medium)
	
	
	# This will dynamically change the foveation level up to the previous level
	vr.set_enable_dynamic_foveation(1)
	
	print("== avalible rates ==")
	var avalibleRates = vr.get_supported_display_refresh_rates()
	for rate in avalibleRates:
		print(rate)
	var highestRate = avalibleRates[avalibleRates.size()-1]
	print("highestRate: %s" % String(highestRate))
	#vr.set_display_refresh_rate(highestRate)
	
	


func init_analytics():
	var file = File.new()
	if file.open('res://keys.json', File.READ) != 0:
		print("Error keys opening file")
		return
	
	var serialized = file.get_as_text()
	var keys = JSON.parse(serialized).result
	file.close()
	
	var gaKeys = keys["game_analytics"]
	
	# configure the keys
	GameAnalytics.game_key = gaKeys["game_key"]
	GameAnalytics.secret_key = gaKeys["secret_key"]
	
	# Start the session
	GameAnalytics.start_session()
