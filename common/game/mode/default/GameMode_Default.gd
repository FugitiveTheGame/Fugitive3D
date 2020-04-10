extends Spatial

var stateMachine := FSM.new()
onready var winZones := get_tree().get_nodes_in_group(Groups.WIN_ZONE)

func get_hider_spawns() -> Array:
	return $HiderSpawns.get_children()


func get_seeker_spawns() -> Array:
	return $SeekerSpawns.get_children()


func _physics_process(delta):
	if not isGameOver():
		checkWinConditions()


func isGameOver() -> bool:
	return get_parent().gameOver


func checkWinConditions():
	# Only the server will end the game
	if not get_tree().is_network_server():
		return
	
	var hiders = get_tree().get_nodes_in_group(Hider.GROUP)
	var seekers = get_tree().get_nodes_in_group(Seeker.GROUP)
	
	# We are debugging if there is exactly 1 player
	var isDebugging = (hiders.empty() and seekers.size() == 1) or (seekers.empty() and hiders.size() == 1)
	
	# Normal win condition:
	# Either all hiders are frozen OR
	# all non-frozen hiders are in a winzone
	if not isDebugging:
		var allHidersFrozen := true
		var allUnfrozenSeekersInWinZone := true
	
		for hider in hiders:
			if (not hider.frozen):
				allHidersFrozen = false
				for winZone in winZones:
					# Now, check if this hider is in the win zone.
					if (not winZone.overlaps_body(hider.playerBody)):
						allUnfrozenSeekersInWinZone = false
		
		if allHidersFrozen or allUnfrozenSeekersInWinZone:
			get_parent().finish_game()
	# Debug win condition:
	# The only player enteres any win zone
	else:
		var player
		if not hiders.empty():
			player = hiders[0]
		else:
			player = seekers[0]
		
		var body = player.playerBody
		for winZone in winZones:
			# Now, check if this hider is in the win zone.
			if winZone.overlaps_body(body):
				get_parent().finish_game()
				break
