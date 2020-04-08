tool
extends Spatial

func _ready():
	if Engine.editor_hint:
		var tool_time_mesh = CSGSphere.new()
		tool_time_mesh.radius = 0.25
		add_child(tool_time_mesh)
