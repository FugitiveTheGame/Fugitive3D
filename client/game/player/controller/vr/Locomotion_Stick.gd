extends "res://addons/OQ_Toolkit/OQ_ARVROrigin/scripts/Locomotion_Stick.gd"

var allowMovement := true
var allowTurn := true


func _ready():
	movmenet_orientation = UserData.data.vr_movement_orientation
	enable_vignette = UserData.data.vr_movement_vignetting
	

func move(dt):
	if allowMovement:
		.move(dt)


func turn(dt):
	if allowTurn:
		.turn(dt)
