extends Control

export(NodePath) var playerPath: NodePath
onready var player := get_node(playerPath) as Hider
onready var visibilityBar := $ProgressBar


func _ready():
	visibilityBar.max_value = 1.0

func _process(delta):
	visibilityBar.value = player.current_visibility
