extends Spatial

onready var redLight := get_node("RedLight")
onready var blueLight := get_node("BlueLight")


func _ready():
	if Utils.renderer_is_gles2():
		redLight.hide()
		blueLight.hide()
		$Timer.autostart = false
		$Timer.stop()
	


func _on_Timer_timeout():
	if redLight.visible:
		redLight.hide()
		blueLight.show()
	else:
		redLight.show()
		blueLight.hide()
