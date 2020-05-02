tool
extends Spatial

func _ready():
	if Engine.editor_hint:
		var tool_time_mesh := CSGSphere.new()
		tool_time_mesh.radius = 0.25
		add_child(tool_time_mesh)
		
		var tool_time_mesh_directional := CSGBox.new()
		tool_time_mesh_directional.width = 0.1
		tool_time_mesh_directional.height = 0.1
		tool_time_mesh_directional.depth = 0.5
		add_child(tool_time_mesh_directional)
		tool_time_mesh_directional.translate(Vector3(0.0, 0.0, -0.25))
