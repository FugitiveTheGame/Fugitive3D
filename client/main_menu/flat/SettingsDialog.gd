extends WindowDialog

export(NodePath) var fullscreenCheckboxPath: NodePath
onready var fullscreenCheckbox := get_node(fullscreenCheckboxPath) as CheckBox


export(NodePath) var mouseSensetivityLabelPath: NodePath
onready var mouseSensetivityLabel := get_node(mouseSensetivityLabelPath) as Label

export(NodePath) var mouseSensetivitySliderPath: NodePath
onready var mouseSensetivitySlider := get_node(mouseSensetivitySliderPath) as HSlider


const MOUSE_SENSETIVITY_CONTENT := "Look Sensitivity: %1.1f"


func _ready():
	fullscreenCheckbox.visible = not OS.has_touchscreen_ui_hint()


func load_data():
	fullscreenCheckbox.pressed = UserData.data.full_screen
	mouseSensetivityLabel.text = MOUSE_SENSETIVITY_CONTENT % UserData.data.flat_mouse_sensetivity
	mouseSensetivitySlider.value = UserData.data.flat_mouse_sensetivity


func _on_SettingsDialog_about_to_show():
	load_data()


func _on_SettingsDialog_popup_hide():
	UserData.save_data()


func _on_FullScreenCheckBox_toggled(button_pressed):
	OS.window_fullscreen = button_pressed
	
	ProjectSettings.set_setting("display/window/size/fullscreen", button_pressed)
	ProjectSettings.save()



func _on_MouseSensetivitySlider_value_changed(value):
	UserData.data.flat_mouse_sensetivity = value
	mouseSensetivityLabel.text = MOUSE_SENSETIVITY_CONTENT % UserData.data.flat_mouse_sensetivity
