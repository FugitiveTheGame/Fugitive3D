extends Control

export(NodePath) var playerPath: NodePath
onready var player := get_node(playerPath) as FugitivePlayer
onready var indicator := $Label as Label


func _process(delta):
	if player.frozen:
		if not indicator.visible:
			indicator.show()
	else:
		if indicator.visible:
			indicator.hide()
