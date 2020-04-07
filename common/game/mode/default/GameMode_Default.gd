extends Spatial


func get_hider_spawns() -> Array:
	return $HiderSpawns.get_children()


func get_seeker_spawns() -> Array:
	return $SeekerSpawns.get_children()


func _on_WinArea_body_entered(body):
	# Just for debugging, ANYONE entering causes the game to end
	get_parent().finish_game()
