extends Control

export(NodePath) var playerPath: NodePath
onready var player := get_node(playerPath) as Player
onready var staminaBar := $ProgressBar as ProgressBar
onready var icon := $TextureRect as TextureRect


var icon_stamina := load("res://client/game/player/hud/ic_stamina.png")
var icon_exhausted := load("res://client/game/mode/fugitive/hud/ic_exhausted.webp")
var showing_exhausted := false

func _ready():
	staminaBar.max_value = player.stamina_max


func _process(delta):
	staminaBar.value = player.stamina
	
	if player.exhausted:
		if not showing_exhausted:
			icon.texture = icon_exhausted
			showing_exhausted = true
	else:
		if showing_exhausted:
			icon.texture = icon_stamina
			showing_exhausted = false
