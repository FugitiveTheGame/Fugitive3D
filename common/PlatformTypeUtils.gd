extends Object
class_name PlatformTypeUtils

enum PlatformType { FlatDesktop, FlatMobile, VrDesktop, VrMobile, Unset }
enum PlatformCategory { Flat, Vr, Unset }


static func get_platform_type() -> int:
	var type: int
	if OS.has_feature("client_flat") and OS.has_feature("mobile"):
		type = PlatformType.FlatMobile
	elif OS.has_feature("client_flat"):
		type = PlatformType.FlatDesktop
	elif VrUtils.isVrClient():
		if OS.has_feature("client_vr_desktop"):
			type = PlatformType.VrDesktop
		elif OS.has_feature("client_vr_mobile"):
			type = PlatformType.VrMobile
	# Debug builds from the editor expect this
	else:
		type = PlatformType.FlatDesktop
	
	return type


static func get_platform_category() -> int:
	var category: int
	
	match get_platform_type():
		PlatformType.FlatDesktop:
			category = PlatformCategory.Flat
		PlatformType.FlatMobile:
			category = PlatformCategory.Flat
		PlatformType.VrDesktop:
			category = PlatformCategory.Vr
		PlatformType.VrMobile:
			category = PlatformCategory.Vr
		_:
			category = PlatformCategory.Unset
	
	return category


static func print_platform_type(platformType: int) -> String:
	match platformType:
		PlatformType.FlatDesktop:
			return "Desktop"
		PlatformType.FlatMobile:
			return "Mobile"
		PlatformType.VrDesktop:
			return "PC VR"
		PlatformType.VrMobile:
			return "Mobile VR"
		_:
			return "Unknown"


static func platform_type_icon(platformType: int) -> String:
	match platformType:
		PlatformType.FlatDesktop:
			return "res://common/lobby/client_type_pc.png"
		PlatformType.FlatMobile:
			return "res://common/lobby/client_type_mobile.png"
		PlatformType.VrDesktop:
			return "res://common/lobby/client_type_vr.png"
		PlatformType.VrMobile:
			return "res://common/lobby/client_type_vr.png"
		_:
			return "res://common/lobby/client_type_pc.png"
