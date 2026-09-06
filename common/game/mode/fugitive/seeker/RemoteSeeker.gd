extends CharacterBody3D

@onready var player := $Player as FugitivePlayer

func _ready():
	player.set_not_local_player()


func get_player():
	return player


func on_car_entered(car):
	pass


func on_car_exited(car):
	pass


func car_rotate(angle: float):
	rpc("on_car_rotate", angle)


@rpc("any_peer", "call_local", "unreliable") func on_car_rotate(angle: float):
	rotate_y(angle)


func _process(delta):
	# Client side prediction
	if not player.gameEnded and not player.frozen:
		set_velocity(player.velocity)
		set_up_direction(Vector3(0.0, 1.0, 0.0))
		move_and_slide()
		player.velocity = velocity
	else:
		player.isMoving = false
	
	# Stick the user's butt in their seat!
	if player.car != null:
		var seat = player.car.find_players_seat(player.id)
		if seat != null:
			global_transform.origin = seat.global_transform.origin

