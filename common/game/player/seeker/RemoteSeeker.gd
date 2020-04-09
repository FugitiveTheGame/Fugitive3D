extends KinematicBody

onready var player := $Player as Player

func _ready():
	player.set_not_local_player()

func get_player():
	return player
