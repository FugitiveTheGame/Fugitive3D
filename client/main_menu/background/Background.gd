extends Spatial

func _ready():
	var lights = get_tree().get_nodes_in_group(Groups.LIGHTS)
	
	$Hider.get_name_label().hide()
	$Cop1.get_name_label().hide()
	
