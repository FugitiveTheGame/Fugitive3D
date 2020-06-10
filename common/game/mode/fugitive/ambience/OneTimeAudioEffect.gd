extends AudioStreamPlayer3D
class_name OneTimeAudioEffect


func _ready():
	connect("finished", self, "on_finished")


func on_finished():
	queue_free()
