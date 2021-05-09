extends Spatial

func _ready():
	Utils.turn_off_baked_lights(self)
	
	$Hider.get_name_label().hide()
	$Cop1.get_name_label().hide()
	
