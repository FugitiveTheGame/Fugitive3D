extends "res://addons/OQ_Toolkit/OQ_ARVROrigin/scripts/OQ_ARVROrigin.gd"

var standingHeight: float
const CROUCH_THRESHOLD := 0.75

onready var camera := $OQ_ARVRCamera
onready var player := $Player

func _ready():
	$Player.set_is_local_player()
	
	# Record the players height when we start here
	call_deferred("set_standing_height")


func set_standing_height():
	standingHeight = camera.translation.y


func _process(delta):
	var curHeight = camera.translation.y
	var curPercent = curHeight / standingHeight
	
	# If the player's is different enough, consider them crouching
	if curHeight < standingHeight and curPercent < CROUCH_THRESHOLD:
		player.is_crouching = true
	else:
		player.is_crouching = false
	
	# Handle VR controller input
	if vr.button_just_released(vr.BUTTON.B):
		set_standing_height()


func _physics_process(delta):
	var totalTranslation = translation
	
	# We need to incorporate head turn into our network rotation
	var totalRotation = rotation
	totalRotation.y += camera.rotation.y
	
	player.rpc_unreliable("network_update", totalTranslation, totalRotation, player.is_crouching)
	
	var fps := Engine.get_frames_per_second()
	$OQ_LeftController/FpsLabel.set_label_text("%d fps" % fps)
