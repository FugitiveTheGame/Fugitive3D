extends Window

@export var fullscreenCheckboxPath: NodePath
@onready var fullscreenCheckbox := get_node(fullscreenCheckboxPath) as CheckBox

@export var controlHintsCheckboxPath: NodePath
@onready var controlHintsCheckbox := get_node(controlHintsCheckboxPath) as CheckBox

@export var analyticsCheckboxPath: NodePath
@onready var analyticsCheckbox := get_node(analyticsCheckboxPath) as CheckBox

@export var mouseSensetivityLabelPath: NodePath
@onready var mouseSensetivityLabel := get_node(mouseSensetivityLabelPath) as Label

@export var mouseSensetivitySliderPath: NodePath
@onready var mouseSensetivitySlider := get_node(mouseSensetivitySliderPath) as HSlider

@export var joystickSensetivityLabelPath: NodePath
@onready var joystickSensetivityLabel := get_node(joystickSensetivityLabelPath) as Label

@export var joystickSensetivitySliderPath: NodePath
@onready var joystickSensetivitySlider := get_node(joystickSensetivitySliderPath) as HSlider


const MOUSE_SENSETIVITY_CONTENT := "Mouse Look Sensitivity: %1.1f"
const JOYSTICK_SENSETIVITY_CONTENT := "Joystick Look Sensitivity: %1.1f"


func _ready():
	fullscreenCheckbox.visible = DisplayUtils.supports_fullscreen_toggle()
	controlHintsCheckbox.visible = ControlHintsHud.is_supported()


func load_data():
	fullscreenCheckbox.button_pressed = UserData.data.fullscreen
	controlHintsCheckbox.button_pressed = UserData.data.on_screen_controls
	analyticsCheckbox.button_pressed = UserData.data.analytics_enabled
	mouseSensetivityLabel.text = MOUSE_SENSETIVITY_CONTENT % UserData.data.flat_mouse_sensetivity
	mouseSensetivitySlider.value = UserData.data.flat_mouse_sensetivity
	joystickSensetivityLabel.text = JOYSTICK_SENSETIVITY_CONTENT % UserData.data.flat_controller_sensetivity
	joystickSensetivitySlider.value = UserData.data.flat_controller_sensetivity


func _on_SettingsDialog_about_to_show():
	load_data()


func _on_SettingsDialog_popup_hide():
	# Connected to visibility_changed, which also fires on show
	if visible:
		return
	UserData.save_data()


func _on_FullScreenCheckBox_toggled(button_pressed):
	UserData.data.fullscreen = button_pressed
	DisplayUtils.apply_fullscreen(button_pressed)



func _on_MouseSensetivitySlider_value_changed(value):
	UserData.data.flat_mouse_sensetivity = value
	mouseSensetivityLabel.text = MOUSE_SENSETIVITY_CONTENT % UserData.data.flat_mouse_sensetivity


func _on_JoystickSensetivitySlider_value_changed(value):
	UserData.data.flat_controller_sensetivity = value
	joystickSensetivityLabel.text = JOYSTICK_SENSETIVITY_CONTENT % UserData.data.flat_controller_sensetivity


func _on_ControlHintsCheckBox_toggled(button_pressed):
	UserData.data.on_screen_controls = button_pressed


func _on_AnalyticsCheckBox_toggled(button_pressed):
	UserData.data.analytics_enabled = button_pressed
	GameAnalytics.collection_enabled = button_pressed
