extends Node

# Change this when debugging from the editor
var debug_is_server := false


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
		print("Could not detect application type! Using debug selection.")
		if debug_is_server:
			go_to_server()
		else:
			go_to_client()


func go_to_client():
	print("Is client")
	get_tree().change_scene("res://client/ClientEntry.tscn")


func go_to_server():
	print("Is server")
	get_tree().change_scene("res://server/ServerEntry.tscn")
