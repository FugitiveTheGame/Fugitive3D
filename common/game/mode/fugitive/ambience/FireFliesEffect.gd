extends AmbientVisualEffect


func initialize_effect(player):
	# Move the 
	var fireFliesParticles = $FireFliesParticles
	assert(fireFliesParticles != null)
	fireFliesParticles.get_parent().remove_child(fireFliesParticles)
	player.add_child(fireFliesParticles)
