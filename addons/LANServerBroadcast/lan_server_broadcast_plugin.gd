tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("ServerAdvertiser", "Node", load("server_advertiser/ServerAdvertiser.gd"), load("server_advertiser/ServerAdvertiser.png"))
	add_custom_type("ServerListener", "Node", load("server_listener/ServerListener.gd"), load("server_listener/ServerListener.png"))


func _exit_tree():
	remove_custom_type("ServerAdvertiser")
	remove_custom_type("ServerListener")
