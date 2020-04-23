extends "res://client/game/mode/fugitive/FlatFugitiveController.gd"

export(NodePath) var car_lock_hud_path: NodePath
onready var car_lock_hud := get_node(car_lock_hud_path)

func _input(event: InputEvent):
	if event.is_action_pressed("flat_seeker_lock"):
		var car = get_nearest_car()
		if car != null and player.can_lock_car(car):
			car_lock_hud.start_locking()
	elif event.is_action_released("flat_seeker_lock"):
		var car = get_nearest_car()
		if car != null:
			car_lock_hud.stop_locking()
	
	if event.is_action_released("flat_seeker_flashlight") and player.car == null:
		$Flashlight.toggle_on()


func _process(delta):
	# Not allow to move while locking
	if player.is_moving() and car_lock_hud.is_locking():
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
