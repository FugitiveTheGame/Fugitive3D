tool
extends Spatial
class_name CarSeat

export(bool) var is_driver_seat := false

onready var position := transform.origin
var occupant: FugitivePlayer = null


func _ready():
	if Engine.editor_hint:
		var tool_time_tall_mesh = CSGBox.new()
		tool_time_tall_mesh.width = 0.1
		tool_time_tall_mesh.height = 0.5
		tool_time_tall_mesh.depth = 0.1
		tool_time_tall_mesh.translation.y += 0.25
		add_child(tool_time_tall_mesh)
		
		var tool_time_mesh = CSGSphere.new()
		tool_time_mesh.radius = 0.15
		add_child(tool_time_mesh)


func is_empty() -> bool:
	return occupant == null


func rotate_occupant(angle: float):
	if occupant != null:
		if is_instance_valid(occupant):
			occupant.playerController.car_rotate(angle)
		else:
			occupant = null
