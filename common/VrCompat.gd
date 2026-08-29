extends Node

# Temporary stand-in for the OQ_Toolkit "vr" autoload while the VR layer is
# rebuilt on OpenXR. Keeps the flat game running; every VR entry point no-ops.

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


func initialize() -> bool:
	log_info("VrCompat.initialize(): VR support not yet ported, ignoring")
	return false


func switch_scene(scene_path: String):
	get_tree().change_scene_to_file(scene_path)


func set_extra_latency_mode(_mode):
	pass


func set_foveation_level(_level):
	pass


func set_enable_dynamic_foveation(_enable: bool):
	pass


func set_display_refresh_rate_to_highest():
	pass


func is_oculus_quest_1_device() -> bool:
	return false


func is_oculus_quest_2_device() -> bool:
	return false


func log_info(message: String):
	print(message)
