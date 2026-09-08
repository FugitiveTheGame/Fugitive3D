extends GdUnitTestSuite

# The dialog reaches its controls through exported NodePaths, so a node renamed
# in the scene resolves to null with no error until a player opens Settings
const SCENE := "res://client/main_menu/flat/SettingsDialog.tscn"

var saved_mouse: float
var saved_joystick: float


func before_test() -> void:
	saved_mouse = UserData.data.flat_mouse_sensetivity
	saved_joystick = UserData.data.flat_controller_sensetivity


func after_test() -> void:
	UserData.data.flat_mouse_sensetivity = saved_mouse
	UserData.data.flat_controller_sensetivity = saved_joystick


func test_look_sliders_show_the_stored_settings() -> void:
	var dialog := await open_dialog(1.5, 0.4)

	assert_float(dialog.mouseSensetivitySlider.value).is_equal_approx(1.5, 0.001)
	assert_float(dialog.joystickSensetivitySlider.value).is_equal_approx(0.4, 0.001)
	assert_str(dialog.mouseSensetivityLabel.text).is_equal("Mouse Look Sensitivity: 1.5")
	assert_str(dialog.joystickSensetivityLabel.text).is_equal("Joystick Look Sensitivity: 0.4")


func test_look_sliders_are_stored_independently() -> void:
	var dialog := await open_dialog(1.0, 1.0)

	dialog._on_MouseSensetivitySlider_value_changed(1.8)
	dialog._on_JoystickSensetivitySlider_value_changed(0.3)

	assert_float(UserData.data.flat_mouse_sensetivity).is_equal_approx(1.8, 0.001)
	assert_float(UserData.data.flat_controller_sensetivity).is_equal_approx(0.3, 0.001)


func test_both_look_settings_have_defaults() -> void:
	var defaults = UserData.get_default_data()
	assert_bool(defaults.has("flat_mouse_sensetivity")).is_true()
	assert_bool(defaults.has("flat_controller_sensetivity")).is_true()


func open_dialog(mouse: float, joystick: float) -> Window:
	UserData.data.flat_mouse_sensetivity = mouse
	UserData.data.flat_controller_sensetivity = joystick

	var dialog := auto_free(load(SCENE).instantiate()) as Window
	add_child(dialog)
	await await_idle_frame()
	dialog.load_data()
	return dialog
