extends "res://common/game/player/Player.gd"
class_name FugitivePlayer

signal local_player_ready

var playerType: int
var frozen := false

var gameStarted := false
var gameEnded := false


func is_playing() -> bool:
	return gameStarted and not gameEnded


func freeze():
	rpc("on_freeze")


remotesync func on_freeze():
	print("Player frozen: %d" % get_network_master())
	frozen = true


func unfreeze():
	rpc("on_unfreeze")


remotesync func on_unfreeze():
	print("Player unfrozen: %d" % get_network_master())
	frozen = false


func set_ready():
	print("abrown: Player reporting ready")
	emit_signal("local_player_ready")


func on_game_state_changed(newState: State, via: Transition):
	print("Local Client State: %s" % newState.name)
	match newState.name:
		FugitiveStateMachine.STATE_NOT_READY:
			on_state_not_ready()
			if playerController.has_method("on_state_not_ready"):
				playerController.on_state_not_ready()
		FugitiveStateMachine.STATE_READY:
			if playerController.has_method("on_state_ready"):
				playerController.on_state_ready()
		FugitiveStateMachine.STATE_COUNTDOWN:
			if playerController.has_method("on_state_countdown"):
				playerController.on_state_countdown()
		FugitiveStateMachine.STATE_PLAYING_HEADSTART:
			gameStarted = true
			on_state_playing_headstart()
			if playerController.has_method("on_state_headstart"):
				playerController.on_state_headstart()
		FugitiveStateMachine.STATE_PLAYING:
			on_state_playing()
			if playerController.has_method("on_state_playing"):
				playerController.on_state_playing()
		FugitiveStateMachine.STATE_GAME_OVER:
				gameEnded = true


func on_state_not_ready():
	freeze()
	print("Local Client State: Not Ready")


func on_state_playing_headstart():
	pass


func on_state_playing():
	print("FugPlay: on_state_playing()")
	pass
