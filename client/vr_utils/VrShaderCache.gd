extends Spatial

func _ready():
	#show()
	# disable this for the moment as it does not appear to be working
	pass


func _on_HideTimer_timeout():
	for child in get_children():
		if child is Spatial:
			child.hide()
