extends "res://addons/OQ_Toolkit/OQ_ARVROrigin/scripts/Locomotion_Stick.gd"

var allowMovement := true
var allowTurn := true


func move(dt):
	if allowMovement:
		.move(dt)


func turn(dt):
	if allowTurn:
		.turn(dt)
