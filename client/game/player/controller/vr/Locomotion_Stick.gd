extends "res://addons/OQ_Toolkit/OQ_ARVROrigin/scripts/Locomotion_Stick.gd"

var allowMovement := true

func move(dt):
	if allowMovement:
		.move(dt)
