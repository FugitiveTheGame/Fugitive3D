tool
extends Spatial
class_name CarSeat

export(bool) var is_driver_seat := false

onready var position := transform.origin
var occupant: FugitivePlayer = null


func _ready():
	if Engine.editor_hint:
		var tool_time_mesh = CSGSphere.new()
		tool_time_mesh.radius = 0.15
		add_child(tool_time_mesh)


func is_empty() -> bool:
	return occupant == null
