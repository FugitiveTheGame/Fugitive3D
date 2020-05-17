extends WindowDialog

export(NodePath) var standingModeOptionsPath: NodePath
onready var standingModeOptions := get_node(standingModeOptionsPath) as OptionButton

export(NodePath) var movementOrientationOptionsPath: NodePath
onready var movementOrientationOptions := get_node(movementOrientationOptionsPath) as OptionButton

export(NodePath) var movementHandOptionsPath: NodePath
onready var movementHandOptions := get_node(movementHandOptionsPath) as OptionButton

export(NodePath) var movementVignettingCheckboxPath: NodePath
onready var movementVignettingCheckbox := get_node(movementVignettingCheckboxPath) as CheckBox


func _ready():
	# $TODO: https://github.com/GodotVR/godot_oculus_mobile/issues/72
	# Once that issue is fixed, then this can work on the Quest
	movementVignettingCheckbox.visible = not OS.has_feature("mobile")


func load_data():
	if UserData.data.vr_standing:
		standingModeOptions.selected = 0
	else:
		standingModeOptions.selected = 1
	
	movementVignettingCheckbox.pressed = UserData.data.vr_movement_vignetting
	movementOrientationOptions.selected = UserData.data.vr_movement_orientation
	movementHandOptions.selected = UserData.data.vr_movement_hand


func _on_SettingsDialog_about_to_show():
	load_data()


func _on_SettingsDialog_popup_hide():
	UserData.save_data()


func _on_MovementOrientationOptions_item_selected(id):
	UserData.data.vr_movement_orientation = id


func _on_VignettingCheckBox_toggled(button_pressed):
	UserData.data.vr_movement_vignetting = button_pressed
 

func _on_MovementHandOptions_item_selected(id):
	UserData.data.vr_movement_hand = id


func _on_StandingModeOptions_item_selected(id):
	match id:
		0:
			UserData.data.vr_standing = true
		1:
			UserData.data.vr_standing = false
	
	# Normally we just save on dialog close, but this one we want
	# real-time feedback to the user
	UserData.save_data()
