extends Node

# OpenXR-backed replacement for the OQ_Toolkit "vr" singleton. The VR rig
# registers its nodes when it enters the tree; button and axis queries are
# answered from the registered XRController3D nodes via OpenXR actions, so
# the game scripts keep the same vr.* surface they had on OQ_Toolkit.

# Kept for ClientEntry compatibility with the old OVR tuning calls.
class OvrVrApiTypes:
	enum OvrExtraLatencyMode {
		VRAPI_EXTRA_LATENCY_MODE_OFF,
		VRAPI_EXTRA_LATENCY_MODE_ON,
		VRAPI_EXTRA_LATENCY_MODE_DYNAMIC,
	}

var ovrVrApiTypes = OvrVrApiTypes

enum FoveatedRenderingLevel {
	Off,
	Low,
	Medium,
	High,
	HighTop,
}

enum BUTTON {
	A,
	B,
	X,
	Y,
	ENTER,
	LEFT_INDEX_TRIGGER,
	RIGHT_INDEX_TRIGGER,
	LEFT_GRIP_TRIGGER,
	RIGHT_GRIP_TRIGGER,
	LEFT_THUMBSTICK,
	RIGHT_THUMBSTICK,
}

enum AXIS {
	LEFT_JOYSTICK_X,
	LEFT_JOYSTICK_Y,
	RIGHT_JOYSTICK_X,
	RIGHT_JOYSTICK_Y,
}

const LEFT := true
const RIGHT := false

# BUTTON -> [is_left_hand, OpenXR action name]
const BUTTON_ACTIONS := {
	BUTTON.A: [RIGHT, "ax_button"],
	BUTTON.B: [RIGHT, "by_button"],
	BUTTON.X: [LEFT, "ax_button"],
	BUTTON.Y: [LEFT, "by_button"],
	BUTTON.ENTER: [LEFT, "menu_button"],
	BUTTON.LEFT_INDEX_TRIGGER: [LEFT, "trigger_click"],
	BUTTON.RIGHT_INDEX_TRIGGER: [RIGHT, "trigger_click"],
	BUTTON.LEFT_GRIP_TRIGGER: [LEFT, "grip_click"],
	BUTTON.RIGHT_GRIP_TRIGGER: [RIGHT, "grip_click"],
	BUTTON.LEFT_THUMBSTICK: [LEFT, "primary_click"],
	BUTTON.RIGHT_THUMBSTICK: [RIGHT, "primary_click"],
}

var xr_interface: XRInterface = null

var vrOrigin: XROrigin3D = null
var vrCamera: XRCamera3D = null
var leftController: XRController3D = null
var rightController: XRController3D = null

var _pressed := {}
var _previously_pressed := {}


func _physics_process(_delta):
	# Snapshot button state once per physics frame so the just_* queries give
	# every caller the same answer. Autoloads process ahead of the scene.
	_previously_pressed = _pressed.duplicate()
	for button in BUTTON_ACTIONS:
		_pressed[button] = _read_button(button)


func register_rig(origin: XROrigin3D, camera: XRCamera3D, left: XRController3D, right: XRController3D):
	vrOrigin = origin
	vrCamera = camera
	leftController = left
	rightController = right


func unregister_rig(origin: XROrigin3D):
	if vrOrigin == origin:
		vrOrigin = null
		vrCamera = null
		leftController = null
		rightController = null


func initialize() -> bool:
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface == null:
		log_warning("OpenXR interface not found")
		return false

	if not xr_interface.is_initialized() and not xr_interface.initialize():
		log_warning("OpenXR failed to initialize")
		return false

	get_viewport().use_xr = true
	# The headset runtime paces frames, so desktop vsync only adds latency
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	log_info("OpenXR initialized")
	return true


func is_initialized() -> bool:
	return xr_interface != null and xr_interface.is_initialized()


func switch_scene(scene_path: String):
	get_tree().change_scene_to_file(scene_path)


func _read_button(button) -> bool:
	var mapping = BUTTON_ACTIONS.get(button)
	if mapping == null:
		return false
	var controller := leftController if mapping[0] == LEFT else rightController
	if controller == null:
		return false
	return controller.is_button_pressed(mapping[1])


func button_pressed(button) -> bool:
	return _pressed.get(button, false)


func button_just_pressed(button) -> bool:
	return _pressed.get(button, false) and not _previously_pressed.get(button, false)


func button_just_released(button) -> bool:
	return not _pressed.get(button, false) and _previously_pressed.get(button, false)


func get_controller_axis(axis) -> float:
	match axis:
		AXIS.LEFT_JOYSTICK_X:
			return leftController.get_vector2("primary").x if leftController else 0.0
		AXIS.LEFT_JOYSTICK_Y:
			return leftController.get_vector2("primary").y if leftController else 0.0
		AXIS.RIGHT_JOYSTICK_X:
			return rightController.get_vector2("primary").x if rightController else 0.0
		AXIS.RIGHT_JOYSTICK_Y:
			return rightController.get_vector2("primary").y if rightController else 0.0
	return 0.0


func get_current_player_height() -> float:
	if vrCamera == null:
		return 0.0
	return vrCamera.transform.origin.y


func set_extra_latency_mode(_mode):
	# OVR-specific, no OpenXR equivalent
	pass


func set_foveation_level(level):
	if xr_interface == null:
		return
	# OQ levels Off/Low/Medium/High/HighTop map onto OpenXR 0..3
	xr_interface.set("foveation_level", clampi(level, 0, 3))


func set_enable_dynamic_foveation(enable: bool):
	if xr_interface == null:
		return
	xr_interface.set("foveation_dynamic", enable)


func set_display_refresh_rate_to_highest():
	if xr_interface == null or not xr_interface.has_method("get_available_display_refresh_rates"):
		return
	var rates: Array = xr_interface.get_available_display_refresh_rates()
	if rates.is_empty():
		return
	var highest: float = rates.max()
	xr_interface.set("display_refresh_rate", highest)
	log_info("Display refresh rate set to %s" % highest)


func is_oculus_quest_1_device() -> bool:
	var model := OS.get_model_name()
	return model.contains("Quest") and not model.contains("Quest 2") and not model.contains("Quest 3")


func is_oculus_quest_2_device() -> bool:
	return OS.get_model_name().contains("Quest 2")


func log_info(message: String):
	print(message)


func log_warning(message: String):
	push_warning(message)
