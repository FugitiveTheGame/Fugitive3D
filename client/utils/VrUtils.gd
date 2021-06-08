extends Object
class_name VrUtils


static func isVrCompatibleOs():
	var vrCompatibleOs := ["windows", "x11", "android"]
	var osName = OS.get_name().to_lower()
	return vrCompatibleOs.find(osName) == 0


static func isVrClient() -> bool:
	if OS.has_feature("vr"):
		return true
	elif should_force_vr() and isVrCompatibleOs():
		return true
	else:
		return false


static func should_force_vr() -> bool:
	var forceVr := false
	var args := OS.get_cmdline_args()
	for arg in args:
		if arg == "--vr":
			forceVr = true
			break
	return forceVr
