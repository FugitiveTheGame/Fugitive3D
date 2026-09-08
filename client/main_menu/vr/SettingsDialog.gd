extends Window

@export var standingModeOptionsPath: NodePath
@onready var standingModeOptions := get_node(standingModeOptionsPath) as OptionButton

@export var movementOrientationOptionsPath: NodePath
@onready var movementOrientationOptions := get_node(movementOrientationOptionsPath) as OptionButton

@export var movementHandOptionsPath: NodePath
@onready var movementHandOptions := get_node(movementHandOptionsPath) as OptionButton

@export var movementVignettingCheckboxPath: NodePath
@onready var movementVignettingCheckbox := get_node(movementVignettingCheckboxPath) as CheckBox

@export var analyticsCheckboxPath: NodePath
@onready var analyticsCheckbox := get_node(analyticsCheckboxPath) as CheckBox

@export var refreshRateLabelPath: NodePath
@onready var refreshRateLabel := get_node(refreshRateLabelPath) as Label

@export var refreshRateOptionsPath: NodePath
@onready var refreshRateOptions := get_node(refreshRateOptionsPath) as OptionButton

# Item index -> Hz, matching the OptionButton entries in the scene
const REFRESH_RATES := [72, 90]


func _ready():
	# $TODO: https://github.com/GodotVR/godot_oculus_mobile/issues/72
	# Once that issue is fixed, then this can work on the Quest
	movementVignettingCheckbox.visible = not OS.has_feature("mobile")

	var supported := vr.get_supported_refresh_rates()
	var offered := REFRESH_RATES.filter(func(rate): return supported.has(float(rate)))
	var selectable := offered.size() > 1
	refreshRateLabel.visible = selectable
	refreshRateOptions.visible = selectable
	for index in range(REFRESH_RATES.size()):
		refreshRateOptions.set_item_disabled(index, not offered.has(REFRESH_RATES[index]))


func load_data():
	if UserData.data.vr_standing:
		standingModeOptions.selected = 0
	else:
		standingModeOptions.selected = 1
	
	movementVignettingCheckbox.button_pressed = UserData.data.vr_movement_vignetting
	movementOrientationOptions.selected = UserData.data.vr_movement_orientation
	movementHandOptions.selected = UserData.data.vr_movement_hand
	analyticsCheckbox.button_pressed = UserData.data.analytics_enabled
	refreshRateOptions.selected = maxi(REFRESH_RATES.find(int(UserData.data.vr_refresh_rate)), 0)


func _on_SettingsDialog_about_to_show():
	load_data()


func _on_SettingsDialog_popup_hide():
	# Connected to visibility_changed, which also fires on show
	if visible:
		return
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


func _on_RefreshRateOptions_item_selected(id):
	UserData.data.vr_refresh_rate = REFRESH_RATES[id]
	vr.set_display_refresh_rate(float(REFRESH_RATES[id]))
	
	# Normally we just save on dialog close, but this one we want
	# real-time feedback to the user
	UserData.save_data()


func _on_AnalyticsCheckBox_toggled(button_pressed):
	UserData.data.analytics_enabled = button_pressed
	GameAnalytics.collection_enabled = button_pressed
