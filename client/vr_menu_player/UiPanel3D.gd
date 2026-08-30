extends "res://client/game/player/controller/vr/WristHud.gd"

# World-space UI panel. Control or Window children placed under the panel in
# a scene are adopted into the viewport on ready, so menu scenes can keep the
# UI as a plain child node the way the OQ_UI2DCanvas versions did.

@export var viewportSize := Vector2i(1600, 900)
@export var panelSize := Vector2(2.0, 1.125)


func _ready():
	viewport.size = viewportSize

	for child in get_children():
		if child is Control or child is Window:
			remove_child(child)
			viewport.add_child(child)

	var mesh := QuadMesh.new()
	mesh.size = panelSize
	screen.mesh = mesh

	var shape := BoxShape3D.new()
	shape.size = Vector3(panelSize.x, panelSize.y, 0.01)
	($ScreenBody/CollisionShape3D as CollisionShape3D).shape = shape

	super._ready()
