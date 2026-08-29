extends RefCounted
class_name Threshold


var threshold_ms := 1_000

var is_running := false

var last_run := 0


func _init(threshold, start_running = true):
	threshold_ms = threshold
	is_running = start_running
	# Ticks are engine uptime, so a plain 0 would suppress the first check
	last_run = -threshold_ms


func start():
	is_running = true


func stop():
	is_running = false


func reset():
	last_run = -threshold_ms
	start()


func is_exceeded() -> bool:
	var exceeded: bool
	
	if is_running:
		var cur_time := Time.get_ticks_msec()
		if (cur_time - last_run) >= threshold_ms:
			last_run = cur_time
			exceeded = true
		else:
			exceeded = false
	else:
		exceeded = false
	
	return exceeded
