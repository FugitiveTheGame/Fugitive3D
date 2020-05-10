extends KinematicBody

onready var player := $Player as FugitivePlayer

func _ready():
	player.set_not_local_player()


func get_player():
	return player


func on_car_entered(car):
	pass


func on_car_exited(car):
	pass


func _process(delta):
	# Client side prediction
	if not player.gameEnded and not player.frozen:
		player.velocity = move_and_slide(player.velocity, Vector3(0.0, 1.0, 0.0))
