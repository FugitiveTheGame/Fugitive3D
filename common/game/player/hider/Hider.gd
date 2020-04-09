extends "res://common/game/player/Player.gd"
class_name Hider

const GROUP := "hider"

var current_visibility := 1.0 setget set_current_visibility
var frozen := false


func _ready():
	add_to_group(GROUP)


func set_current_visibility(percentVisible: float):
	current_visibility = percentVisible
	
	# If we are a Seeker, use visibility to fade hider out
	var currentPlayer = GameData.get_current_player()
	var playerType = currentPlayer[GameData.PLAYER_TYPE]
	if playerType == GameData.PlayerType.Seeker:
		playerShape.alpha = percentVisible


func update_visibility(percentVisible: float):
	# Never make a hider MORE invisible, if some one else can see the hider
	# then leave them that visible for all Seekers
	if percentVisible > self.current_visibility:
		self.current_visibility = percentVisible


func freeze():
	rpc("on_freeze")


remotesync func on_freeze():
	print("Hider frozen")
	frozen = true
