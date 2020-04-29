extends "res://addons/OQ_Toolkit/OQ_ARVROrigin/scripts/Locomotion_Stick.gd"

var allowMovement := true
var allowTurn := true


func _ready():
	movmenet_orientation = UserData.data.vr_movement_orientation
	enable_vignette = UserData.data.vr_movement_vignetting
	
	match UserData.data.vr_movement_hand:
		0:
			move_left_right = vr.AXIS.LEFT_JOYSTICK_X;
			move_forward_back = vr.AXIS.LEFT_JOYSTICK_Y;
			
			turn_left_right = vr.AXIS.RIGHT_JOYSTICK_X;
		1:
			move_left_right = vr.AXIS.RIGHT_JOYSTICK_X;
			move_forward_back = vr.AXIS.RIGHT_JOYSTICK_Y;
			
			turn_left_right = vr.AXIS.LEFT_JOYSTICK_X;
	

func move(dt):
	if allowMovement:
		.move(dt)


func turn(dt):
	if allowTurn:
		.turn(dt)
