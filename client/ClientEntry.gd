extends Node

# Go to the proper entry for this client
func _ready():
	if OS.has_feature("client_flat"):
		print("Client is Flat")
		go_to_flat()
	elif OS.has_feature("client_vr_desktop"):
		print("Client is PC VR")
		go_to_pc_vr()
	elif OS.has_feature("client_vr_mobile"):
		print("Client is Mobile VR")
		go_to_mobile_vr()
	# Devel branch
	else:
		#go_to_pc_vr()
		#go_to_mobile_vr()
		go_to_flat()


func go_to_flat():
	# Handle initial fullscreen setting
	var fullscreen = UserData.data.full_screen
	if fullscreen != OS.window_fullscreen:
		Utils.set_window_to_screen_size()
		OS.window_fullscreen = UserData.data.full_screen
	
	get_tree().change_scene("res://client/main_menu/flat/FlatMainMenu.tscn")


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
	
