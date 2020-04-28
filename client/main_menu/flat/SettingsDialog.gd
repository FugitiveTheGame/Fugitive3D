extends WindowDialog


func load_data():
	var fullscreen = UserData.data.full_screen
	$FullScreenCheckBox.pressed = fullscreen


func _on_SettingsDialog_about_to_show():
	load_data()


func _on_SettingsDialog_popup_hide():
	UserData.save_data()


func _on_FullScreenCheckBox_toggled(button_pressed):
	UserData.data.full_screen = button_pressed
	OS.window_fullscreen = button_pressed
