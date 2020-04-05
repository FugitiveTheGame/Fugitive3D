extends CollisionShape
	

func get_standing_shape() -> Spatial:
	return $Standing as Spatial


func get_crouching_shape() -> Spatial:
	return $Crouching as Spatial


func set_crouching(is_crouching: bool):
	if is_crouching:
		get_standing_shape().hide()
		get_crouching_shape().show()
	else:
		get_standing_shape().show()
		get_crouching_shape().hide()
