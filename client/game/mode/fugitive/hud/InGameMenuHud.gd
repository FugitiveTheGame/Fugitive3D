extends Control

signal show_help
signal show_exit
signal resume_game


func _on_HelpButton_pressed():
	hide()
	call_deferred("emit_signal", "show_help")


func _on_ExitButton_pressed():
	hide()
	call_deferred("emit_signal", "show_exit")


func _on_ResumeButton_pressed():
	hide()
	call_deferred("emit_signal", "resume_game")
