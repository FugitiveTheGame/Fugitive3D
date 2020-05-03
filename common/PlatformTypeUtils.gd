extends Node

const PLATFORM_TYPE_FLAT := 0
const PLATFORM_TYPE_VR_DESKTOP := 1
const PLATFORM_TYPE_VR_MOBILE := 2

static func get_platform_type() -> int:
	if OS.has_feature("client_flat"):
		return PLATFORM_TYPE_FLAT
	elif OS.has_feature("client_vr_desktop"):
		return PLATFORM_TYPE_VR_DESKTOP
	elif OS.has_feature("client_vr_mobile"):
		return PLATFORM_TYPE_VR_MOBILE
	else:
		return PLATFORM_TYPE_FLAT

static func print_platform_type(platformType: int) -> String:
	match platformType:
		PLATFORM_TYPE_FLAT:
			return "Desktop"
		PLATFORM_TYPE_VR_DESKTOP:
			return "Desktop VR"
		PLATFORM_TYPE_VR_MOBILE:
			return "Mobile VR"
		_:
			return "Unknown"
