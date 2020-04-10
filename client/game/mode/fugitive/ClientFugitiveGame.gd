extends FugitiveGame
class_name ClientFugitiveGame


remotesync func on_pre_configure_complete():
	print("All clients are configured. Starting the game.")
	get_tree().paused = false


remotesync func on_go_to_lobby():
	print("CLIENT: on_go_to_lobby()")
	
	if OS.has_feature("client_flat"):
		go_to_flat_lobby()
	elif OS.has_feature("client_vr_desktop"):
		go_to_pc_vr_lobby()
	elif OS.has_feature("client_vr_mobile"):
		go_to_mobile_vr_lobby()
	else:
		go_to_flat_lobby()


func go_to_flat_lobby():
	get_tree().change_scene("res://client/lobby/flat/FlatLobby.tscn")


func go_to_pc_vr_lobby():
	get_tree().change_scene("res://client/lobby/vr/VrLobby.tscn")


func go_to_mobile_vr_lobby():
	get_tree().change_scene("res://client/lobby/vr/VrLobby.tscn")
