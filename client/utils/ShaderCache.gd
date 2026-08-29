extends Node3D

func _ready():
	show()


func _on_HideTimer_timeout():
	for child in get_children():
		if child is Node3D:
			child.queue_free()
