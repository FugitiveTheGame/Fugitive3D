extends Node
class_name Utils


static func set_window_to_screen_size():
	OS.set_window_size(OS.get_screen_size())

static func get_map_rotation(globalTransform: Transform) -> float:
	return (globalTransform.basis.get_euler().y + deg2rad(180)) * -1.0
