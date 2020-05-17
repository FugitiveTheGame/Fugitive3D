extends Spatial

onready var fpsLabel := $OQ_ARVROrigin/OQ_LeftController/OQ_VisibilityToggle/FpsLabel

var initial_origin: Vector3
var is_standing := true

var seated_offset_meters := 0.15

func _enter_tree():
	UserData.connect("user_data_updated", self, "on_user_data_updated")


func _ready():
	initial_origin = $OQ_ARVROrigin.transform.origin
	
	update_standing()


func _exit_tree():
	UserData.disconnect("user_data_updated", self, "on_user_data_updated")


func _physics_process(delta):
	fpsLabel.set_label_text("%d fps" % Engine.get_frames_per_second())


func on_user_data_updated():
	update_standing()


func update_standing():
	if UserData.data.vr_standing != is_standing:
		if UserData.data.vr_standing:
			$OQ_ARVROrigin.transform.origin = initial_origin
		else:
			$OQ_ARVROrigin.transform.origin = initial_origin
			$OQ_ARVROrigin.transform.origin.y += seated_offset_meters
		
		is_standing = UserData.data.vr_standing
