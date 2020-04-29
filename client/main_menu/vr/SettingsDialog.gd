extends WindowDialog

export(NodePath) var movementOrientationOptionsPath: NodePath
onready var movementOrientationOptions := get_node(movementOrientationOptionsPath) as OptionButton

export(NodePath) var movementVignettingCheckboxPath: NodePath
onready var movementVignettingCheckbox := get_node(movementVignettingCheckboxPath) as CheckBox

func load_data():
	movementOrientationOptions.selected = UserData.data.vr_movement_orientation
	movementVignettingCheckbox.pressed = UserData.data.vr_movement_vignetting


func _on_SettingsDialog_about_to_show():
	load_data()


func _on_SettingsDialog_popup_hide():
	UserData.save_data()


func _on_MovementOrientationOptions_item_selected(id):
	UserData.data.vr_movement_orientation = id


func _on_VignettingCheckBox_toggled(button_pressed):
	UserData.data.vr_movement_vignetting = button_pressed
 
