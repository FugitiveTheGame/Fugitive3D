extends Spatial
class_name AmbientEffect

export(float) var frequency: float = 0.1
var debug := false

func play(localPlayerPos: Vector3):
	if debug:
		var debugShape := CSGSphere.new()
		debugShape.translation = localPlayerPos
		debugShape.radius = 1.0
		"""
		var debugShape := CSGBox.new()
		debugShape.translation = randPos
		debugShape.height = 100.0
		debugShape.width = 1.0
		debugShape.depth = 1.0
		"""
		add_child(debugShape)
