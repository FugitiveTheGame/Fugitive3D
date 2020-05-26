extends AmbientEffect
class_name AmbientVisualEffect

var local_bounding_box := AABB()
export(float) var effect_size: float = 50.0
export(float) var effect_height: float = 2.0


func _ready():
	var halfSize := effect_size / 2.0
	local_bounding_box = AABB(Vector3(-halfSize, 0.0, -halfSize), Vector3(effect_size, effect_height, effect_size) )
