extends Node
class_name PlayerData

var player_data_dictionary: Dictionary

func _ready():
	pass

func load(new_player_data_dictionary: Dictionary):
	player_data_dictionary = new_player_data_dictionary

func get_id() -> int:
	return player_data_dictionary.id
	
func set_id(id: int):
	player_data_dictionary.id = id

func get_name() -> String:
	return player_data_dictionary.name
	
func set_name(name: String):
	player_data_dictionary.name = name

func get_type() -> int:
	return player_data_dictionary.type
	
func set_type(type: int):
	player_data_dictionary.type = type
	
func get_is_host() -> bool:
	return player_data_dictionary.is_host
	
func set_is_host(is_host: bool):
	player_data_dictionary.is_host = is_host
