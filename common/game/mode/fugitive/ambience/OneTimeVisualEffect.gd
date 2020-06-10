extends Spatial
class_name OneTimeVisualEffect

var timer := Timer.new()
var effect_length := 1.0

func _ready():
	"""
	timer.wait_time = effect_length
	timer.autostart = true
	timer.one_shot = true
	timer.add_child(timer)
	timer.connect("timeout", self, "on_timeout")
	"""


func _on_timeout():
	queue_free()
