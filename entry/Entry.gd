extends Node


# Entry point for the whole app
# Determine the type of app this is, and load the entry point for that type
func _ready():
	print("Application started")
	if OS.has_feature("server"):
		go_to_server()
	elif OS.has_feature("client"):
		go_to_client()
	# When running from the editor, this is how we'll default to being a client
	else:
		print("Could not detect application type! Defaulting to client.")
		go_to_client()
		#go_to_server()


func go_to_client():
	print("Is client")
	get_tree().change_scene("res://client/ClientEntry.tscn")


func go_to_server():
	print("Is server")
	get_tree().change_scene("res://server/ServerEntry.tscn")
