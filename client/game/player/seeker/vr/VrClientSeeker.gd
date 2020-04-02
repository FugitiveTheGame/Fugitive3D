extends "res://client/game/player/controller/vr/VrPlayerController.gd"

func _ready():
	$Player.set_is_local_player()


func _physics_process(delta):
	# Copy the hand attitude to the flashlight
	$Flashlight.translation = $OQ_RightController.translation
	$Flashlight.rotation = $OQ_RightController.rotation
