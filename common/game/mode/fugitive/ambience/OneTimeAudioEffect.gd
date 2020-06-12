extends AudioStreamPlayer3D
class_name OneTimeAudioEffect

signal audio_effect_complete(node)


func _ready():
	connect("finished", self, "on_finished")
	play()


func on_finished():
	emit_signal("audio_effect_complete", self)
