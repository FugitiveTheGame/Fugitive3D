extends Control

export(NodePath) var playerPath: NodePath
onready var player := get_node(playerPath) as Hider

onready var label := $SafeLabel as Label


func _ready():
	label.hide()


# If we are in a winzone, show the indicator
func _physics_process(delta):
	var isInWinZone := false
	
	var body := player.playerBody
	var winZones = GameData.currentMap.get_win_zones()
	for zone in winZones:
		if zone.overlaps_body(body):
			isInWinZone = true
			break
	
	if isInWinZone:
		if not label.visible:
			label.show()
	else:
		if label.visible:
			label.hide()
