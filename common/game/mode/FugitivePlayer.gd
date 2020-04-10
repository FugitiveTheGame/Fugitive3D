extends Player
class_name FugitivePlayer

var frozen := false


func freeze():
	rpc("on_freeze")


remotesync func on_freeze():
	print("Hider frozen")
	frozen = true


func unfreeze():
	rpc("on_unfreeze")


remotesync func on_unfreeze():
	print("Hider unfrozen")
	frozen = false


func on_game_state_changed(newState: State, via: Transition):
	print("Local Client State: %s" % newState.name)
	match newState.name:
		FugitiveStateMachine.STATE_NOT_READY:
			on_state_not_ready()
			# Remote controllers probably don't care about this
			if playerController.has_method("on_state_not_ready"):
				playerController.on_state_not_ready()
		FugitiveStateMachine.STATE_READY:
			on_state_ready()
			if playerController.has_method("on_state_ready"):
				playerController.on_state_ready()


func on_state_not_ready():
	freeze()
	print("Local Client State: Not Ready")


func on_state_ready():
	print("Local Client State: Not Ready")
