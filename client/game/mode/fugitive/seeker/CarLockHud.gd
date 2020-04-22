extends Control

signal locking_complete

onready var container := $Container
onready var car_lock_timer := $Container/CarLockTimer as Timer
onready var lock_progress_bar := $Container/ProgressBar as ProgressBar

func start_locking():
	car_lock_timer.start()


func stop_locking():
	car_lock_timer.stop()


func _process(delta):
	if not car_lock_timer.is_stopped():
		if not container.visible:
			container.show()
		lock_progress_bar.value = 100.0 - (car_lock_timer.time_left / car_lock_timer.wait_time) * 100.0
	
	elif container.visible:
		container.hide()


func _on_CarLockTimer_timeout():
	emit_signal("locking_complete")
