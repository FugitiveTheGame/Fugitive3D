extends Spatial


func _on_WinArea_body_entered(body):
	# Just for debugging, ANYONE entering causes the game to end
	get_parent().finish_game()
