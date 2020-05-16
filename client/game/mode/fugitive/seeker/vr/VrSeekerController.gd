extends "res://client/game/mode/fugitive/VrFugitiveController.gd"

onready var car_lock_hud := hud.find_node("CarLockHud", true, false)

export(NodePath) var flashlightPath: NodePath
onready var flashlight := get_node(flashlightPath) as Spatial


func _process(delta):
	if debounced_button_just_released(vr.BUTTON.B) and player.car == null:
		flashlight.toggle_on()
	
	###########################
	# Seeker only car controls
	if vr.button_just_pressed(vr.BUTTON.X):
		var car = get_nearest_car()
		if car != null and player.can_lock_car(car):
			car_lock_hud.start_locking()
	elif vr.button_just_released(vr.BUTTON.X):
		var car = get_nearest_car()
		if car != null:
			car_lock_hud.stop_locking()
	
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


func on_ui_raycast_visibility_changed():
	.on_ui_raycast_visibility_changed()
	
	flashlight.visible = not uiRaycast.visible
