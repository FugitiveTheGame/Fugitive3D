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
	get_tree().change_scene("res://client/main_menu/flat/FlatMainMenu.tscn")


func go_to_pc_vr():
	prepare_pc_vr()
	get_tree().change_scene("res://client/main_menu/vr/VrClientMainMenu.tscn")


func go_to_mobile_vr():
	prepare_mobile_vr()
	get_tree().change_scene("res://client/main_menu/vr/VrClientMainMenu.tscn")


func prepare_pc_vr():
	vr.initialize()


func prepare_mobile_vr():
	vr.initialize()
