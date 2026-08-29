extends Node3D
class_name AmbientEffect

@export var frequency: float = 0.1
var debug := false

func play(localPlayerPos: Vector3):
	if debug:
		var debugShape := CSGSphere3D.new()
		debugShape.position = localPlayerPos
		debugShape.radius = 1.0
		"""
		var debugShape := CSGBox3D.new()
		debugShape.position = randPos
		debugShape.height = 100.0
		debugShape.width = 1.0
		debugShape.depth = 1.0
		"""
		add_child(debugShape)
