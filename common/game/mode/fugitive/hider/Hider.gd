extends "res://common/game/mode/fugitive/FugitivePlayer.gd"
class_name Hider

const GROUP := "hider"

var current_visibility := 1.0 setget set_current_visibility

onready var freeze_sound := $FreezeSound as AudioStreamPlayer3D
onready var unfreeze_sound := $UnfreezeSound as AudioStreamPlayer3D
var initialFreeze := true


func _ready():
	playerType = FugitiveTeamResolver.PlayerType.Hider
	add_to_group(GROUP)

func set_current_visibility(percentVisible: float):
	current_visibility = percentVisible
	
	# If we are a Seeker, use visibility to fade hider out
	if GameData.get_current_player_type() == FugitiveTeamResolver.PlayerType.Seeker:
		playerShape.alpha = percentVisible


func update_visibility(percentVisible: float):
	# Never make a hider MORE invisible, if some one else can see the hider
	# then leave them that visible for all Seekers
	if percentVisible > self.current_visibility:
		self.current_visibility = percentVisible


func _on_UnfreezeArea_body_entered(body):
	# Server authoratative
	if get_tree().is_network_server():
		# If we are frozen, and another hider is tagging us, then unfreeze
		if frozen and body.has_method("get_player") and is_playing():
			var player := body.get_player() as Player
			if player.playerType == FugitiveTeamResolver.PlayerType.Hider:
				unfreeze()
				# Hider being unfrozen records the stat
				FugitivePlayerDataUtility.increment_stat_for_player_id(id, FugitivePlayerDataUtility.STAT_HIDER_UNFROZEN)
				
				# Also grant that rescuing player a stat
				FugitivePlayerDataUtility.increment_stat_for_player_id(player.id, FugitivePlayerDataUtility.STAT_HIDER_UNFREEZER)


remotesync func on_freeze():
	.on_freeze()
	
	if gameStarted:
		freeze_sound.play()
		playerShape.get_frozen_shape().show()


remotesync func on_unfreeze():
	.on_unfreeze()
	playerShape.get_frozen_shape().hide()
	
	if gameStarted and not initialFreeze:
		unfreeze_sound.play()
	else:
		initialFreeze = false


func on_state_playing_headstart():
	if get_tree().is_network_server():
		unfreeze()
