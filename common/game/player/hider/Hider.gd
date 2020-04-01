extends "res://common/game/player/Player.gd"
class_name Hider

const GROUP := "hider"

func _ready():
	add_to_group(GROUP)
