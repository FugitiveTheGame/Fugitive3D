extends Window

@export var fullscreenCheckboxPath: NodePath
@onready var fullscreenCheckbox := get_node(fullscreenCheckboxPath) as CheckBox

@export var mouseSensetivityLabelPath: NodePath
@onready var mouseSensetivityLabel := get_node(mouseSensetivityLabelPath) as Label

@export var mouseSensetivitySliderPath: NodePath
@onready var mouseSensetivitySlider := get_node(mouseSensetivitySliderPath) as HSlider


const MOUSE_SENSETIVITY_CONTENT := "Look Sensitivity: %1.1f"


func _ready():
	fullscreenCheckbox.visible = not DisplayServer.is_touchscreen_available()


func load_data():
	fullscreenCheckbox.button_pressed = ProjectSettings.get_setting("display/window/size/fullscreen") as bool
	mouseSensetivityLabel.text = MOUSE_SENSETIVITY_CONTENT % UserData.data.flat_mouse_sensetivity
	mouseSensetivitySlider.value = UserData.data.flat_mouse_sensetivity


func _on_SettingsDialog_about_to_show():
	load_data()


func _on_SettingsDialog_popup_hide():
	# Connected to visibility_changed, which also fires on show
	if visible:
		return
	UserData.save_data()


func _on_FullScreenCheckBox_toggled(button_pressed):
	get_window().mode = Window.MODE_EXCLUSIVE_FULLSCREEN if (button_pressed) else Window.MODE_WINDOWED
	
	ProjectSettings.set_setting("display/window/size/fullscreen", button_pressed)
	ProjectSettings.save()



func _on_MouseSensetivitySlider_value_changed(value):
	UserData.data.flat_mouse_sensetivity = value
	mouseSensetivityLabel.text = MOUSE_SENSETIVITY_CONTENT % UserData.data.flat_mouse_sensetivity
