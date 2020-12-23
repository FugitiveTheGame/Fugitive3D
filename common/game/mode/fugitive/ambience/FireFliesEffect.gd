extends AmbientVisualEffect


func initialize_effect(player):
	# Quest 1 is not powerful enough, remove the fireflies
	if Utils.is_quest1():
		$FireFliesParticles.queue_free()
	else:
		# Move the effect to the player so it follows them
		var fireFliesParticles = $FireFliesParticles
		assert(fireFliesParticles != null)
		fireFliesParticles.get_parent().remove_child(fireFliesParticles)
		player.add_child(fireFliesParticles)
