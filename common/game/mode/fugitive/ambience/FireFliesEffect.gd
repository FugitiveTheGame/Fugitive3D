extends AmbientVisualEffect


func initialize_effect(player):
	var fireFliesParticles = $FireFliesParticles
	assert(fireFliesParticles != null)
	
	# Quest 1 is not powerful enough, remove the fireflies
	# Also the server can just delete it when the player is null
	if player == null or Utils.is_quest1():
		fireFliesParticles.queue_free()
	else:
		# Move the effect to the player so it follows them
		fireFliesParticles.get_parent().remove_child(fireFliesParticles)
		player.add_child(fireFliesParticles)
