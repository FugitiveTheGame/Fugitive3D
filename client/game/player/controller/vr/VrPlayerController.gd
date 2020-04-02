extends "res://addons/OQ_Toolkit/OQ_ARVROrigin/scripts/OQ_ARVROrigin.gd"

var standingHeight: float
const CROUCH_THRESHOLD := 0.75

func _ready():
	$Player.set_is_local_player()
	
	# Record the players height when we start here
	call_deferred("set_standing_height")


func set_standing_height():
	standingHeight = $OQ_ARVRCamera.translation.y


func _process(delta):
	var curHeight = $OQ_ARVRCamera.translation.y
	#var heightDiff = standingHeight - curHeight
	var curPercent = curHeight / standingHeight
	
	print("%f / %f = %f" % [curHeight, standingHeight, curPercent])
	
	# If the player's is different enough, consider them crouching
	if curHeight < standingHeight and curPercent < CROUCH_THRESHOLD:
		print("Is crouching")
		$Player.is_crouching = true
	else:
		print("Is standing")
		$Player.is_crouching = false
	
	if vr.button_just_released(vr.BUTTON.B):
		set_standing_height()


func _physics_process(delta):
	$Player.rpc_unreliable("network_update", translation, rotation, $Player.is_crouching)
