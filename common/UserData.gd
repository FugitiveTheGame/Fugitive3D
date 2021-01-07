extends Node

signal user_data_updated

const GAME_VERSION := 13
const USER_DATA_VERSION := 7

var file_name := 'user://user_data.json'

var data = get_default_data()
var update_notification_presented := false


static func get_default_data():
	var default = {
		version = USER_DATA_VERSION,
		user_name = '',
		last_ip = '127.0.0.1',
		last_port = ServerNetwork.SERVER_PORT,
		menu_music = true,
		flat_mouse_sensetivity = 1.0,
		vr_standing = true, # Standing
		vr_movement_orientation = 0, # HEAD
		vr_movement_vignetting = false,
		vr_movement_hand = 0 # Left
	}
	
	return default

func _ready():
	print("Game Version: %d" % GAME_VERSION)
	load_data()

func load_data():
	print('Loading user data...')
	# Open a file
	var file = File.new()

	# If we don't have a file, create the basic one	
	if not file.file_exists(file_name):
		print("No user data, create default")
	
		var defaultData = get_default_data()
		save_data(defaultData)
	
	# Read in the data file
	if file.open(file_name, File.READ) != 0:
		print("Error opening file")
		return
	
	var serialized = file.get_line()
	data = parse_json(serialized)
	file.close()
	
	# Data must be purged!
	if not data.has('version') or data.version < USER_DATA_VERSION:
		print('User Data out of data, regenerating')
		# Regenerate user data
		var defaultData = get_default_data()
		save_data(defaultData)
		data = defaultData


func save_data(save_data = self.data):
	print('Saving user data...')
	var file = File.new()
	if file.open(file_name, File.WRITE) != 0:
		print("Error opening file")
		return
	
	var serialized = to_json(save_data)
	file.store_line(serialized)
	file.close()
	
	emit_signal("user_data_updated")
