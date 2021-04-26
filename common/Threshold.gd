extends Reference
class_name Threshold


var threshold_ms := 1_000

var is_running := false

var last_run := 0 setget set_last_run
func set_last_run(v: int):
	assert(false)


func _init(threshold):
	threshold_ms = threshold


func start():
	is_running = true


func stop():
	is_running = false


func reset():
	last_run = 0


func is_exceeded() -> bool:
	var exceeded: bool
	
	if is_running:
		var cur_time := OS.get_system_time_msecs()
		if (cur_time - last_run) >= threshold_ms:
			last_run = cur_time
			exceeded = true
		else:
			exceeded = false
	else:
		exceeded = false
	
	return exceeded
