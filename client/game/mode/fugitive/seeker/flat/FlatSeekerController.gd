extends "res://client/game/mode/fugitive/FlatFugitiveController.gd"

export(NodePath) var car_lock_hud_path: NodePath
onready var car_lock_hud := get_node(car_lock_hud_path)

export(NodePath) var car_lock_button_path: NodePath
onready var car_lock_button := get_node(car_lock_button_path) as TouchScreenButton

export(NodePath) var flashlightPath: NodePath
onready var flashlight := get_node(flashlightPath) as Spatial


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
		flashlight.toggle_on()


func _process(delta):
	# Not allow to move while locking
	if player.is_moving() and car_lock_hud.is_locking():
		car_lock_hud.stop_locking()
	
	if OS.has_touchscreen_ui_hint():
		if player.can_lock_car(get_nearest_car()):
			car_lock_button.show()
		else:
			car_lock_button.hide()


func _on_CarLockHud_locking_complete():
	var car = get_nearest_car()
	if car != null:
		car.lock()
