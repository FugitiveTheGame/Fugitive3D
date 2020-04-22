extends "res://client/game/mode/fugitive/FlatFugitiveController.gd"

onready var car_lock_hud := $HudCanvas/HudContainer/CarLockHud

func _input(event: InputEvent):
	if event.is_action_pressed("flat_seeker_lock"):
		var car = get_nearest_car()
		if car != null and player.can_lock_car(car):
			car_lock_hud.start_locking()
	elif event.is_action_released("flat_seeker_lock"):
		var car = get_nearest_car()
		if car != null:
			car_lock_hud.stop_locking()


func get_nearest_car():
	var closestCar = null
	
	var cars = get_tree().get_nodes_in_group(Groups.CARS)
	for car in cars:
		if car.enterArea.overlaps_body(player.playerBody):
			closestCar = car
			break
	
	return closestCar


func _on_CarLockHud_locking_complete():
	var car = get_nearest_car()
	if car != null:
		car.lock()
