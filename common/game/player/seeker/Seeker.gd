extends "res://common/game/player/Player.gd"
class_name Seeker

const GROUP := "seeker"

func _ready():
	add_to_group(GROUP)
