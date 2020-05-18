extends ConfirmationDialog

signal return_to_main_menu
signal on_exit_dialog_show
signal on_exit_dialog_hide

func show_dialog():
	if not visible:
		popup_centered()
	else:
		hide()


func _on_ExitGameDialog_confirmed():
	emit_signal("return_to_main_menu")


func _on_ExitGameDialog_about_to_show():
	emit_signal("on_exit_dialog_show")


func _on_ExitGameDialog_popup_hide():
	emit_signal("on_exit_dialog_hide")
