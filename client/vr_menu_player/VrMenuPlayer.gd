extends Node3D

@onready var fpsLabel := $Origin/LeftHand/VisibilityToggle/FpsLabel as Label3D

var initial_origin: Vector3
var is_standing := true

var seated_offset_meters := 0.15

func _enter_tree():
	UserData.connect("user_data_updated", Callable(self, "on_user_data_updated"))


func _ready():
	vr.register_rig($Origin, $Origin/Camera, $Origin/LeftHand, $Origin/RightHand)

	initial_origin = $Origin.transform.origin

	update_standing()


func _exit_tree():
	UserData.disconnect("user_data_updated", Callable(self, "on_user_data_updated"))
	vr.unregister_rig($Origin)


func _physics_process(delta):
	fpsLabel.text = "%d fps" % Engine.get_frames_per_second()

	if vr.button_just_pressed(vr.BUTTON.RIGHT_THUMBSTICK):
		inject_ptt_action(true)
	elif vr.button_just_released(vr.BUTTON.RIGHT_THUMBSTICK):
		inject_ptt_action(false)


func on_user_data_updated():
	update_standing()


func update_standing():
	if UserData.data.vr_standing != is_standing:
		if UserData.data.vr_standing:
			$Origin.transform.origin = initial_origin
		else:
			$Origin.transform.origin = initial_origin
			$Origin.transform.origin.y += seated_offset_meters

		is_standing = UserData.data.vr_standing


func inject_ptt_action(pressed: bool):
	var event := InputEventAction.new()
	event.action = "push_to_talk"
	event.pressed = pressed
	Input.parse_input_event(event)
