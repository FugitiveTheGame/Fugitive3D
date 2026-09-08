extends Object
class_name DisplayUtils


static func supports_fullscreen_toggle() -> bool:
	return not DisplayServer.is_touchscreen_available()


static func apply_fullscreen(enabled: bool):
	if not supports_fullscreen_toggle():
		return

	var window := Engine.get_main_loop().root as Window
	window.mode = Window.MODE_EXCLUSIVE_FULLSCREEN if enabled else Window.MODE_WINDOWED
