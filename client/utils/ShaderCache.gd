extends Spatial

func _ready():
	show()


func _on_HideTimer_timeout():
	for child in get_children():
		if child is Spatial:
			child.queue_free()
