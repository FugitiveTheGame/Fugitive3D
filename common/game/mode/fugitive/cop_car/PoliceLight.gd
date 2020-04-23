extends Spatial

onready var redLight := get_node("RedLight")
onready var blueLight := get_node("BlueLight")


func _on_Timer_timeout():
	if redLight.visible:
		redLight.hide()
		blueLight.show()
	else:
		redLight.show()
		blueLight.hide()
