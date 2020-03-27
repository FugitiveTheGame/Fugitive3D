extends Node

# Go to the proper entry for this client
func _ready():
	if OS.has_feature("client_flat"):
		go_to_flat()
	elif OS.has_feature("client_vr_desktop"):
		go_to_pc_vr()
	elif OS.has_feature("client_vr_mobile"):
		go_to_mobile_vr()
	# Devel branch
	else:
		#go_to_mobile_vr()
		go_to_flat()


func go_to_flat():
	get_tree().change_scene("res://client/main_menu/flat/FlatMainMenu.tscn")


func go_to_pc_vr():
	prepare_pc_vr()
	get_tree().change_scene("res://client/main_menu/vr/pc/VrClientMainMenu.tscn")


func go_to_mobile_vr():
	prepare_mobile_vr()
	get_tree().change_scene("res://client/main_menu/vr/mobile/VrClientMainMenu.tscn")


func prepare_pc_vr():
	var VR = ARVRServer.find_interface("Oculus")
	if VR and VR.initialize():
		get_viewport().arvr = true
		get_viewport().hdr = false
		
		OS.vsync_enabled = false
		Engine.target_fps = 90


func prepare_mobile_vr():
	var VR = ARVRServer.find_interface("Oculus")
	if VR and VR.initialize():
		get_viewport().arvr = true
		get_viewport().hdr = false
		
		OS.vsync_enabled = false
		Engine.target_fps = 72
