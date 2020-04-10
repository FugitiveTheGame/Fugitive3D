extends Control

export(NodePath) var playerPath: NodePath
onready var player := get_node(playerPath) as Player
onready var staminaBar := $ProgressBar


func _ready():
	staminaBar.max_value = player.STAMINA_MAX

func _process(delta):
	staminaBar.value = player.stamina
