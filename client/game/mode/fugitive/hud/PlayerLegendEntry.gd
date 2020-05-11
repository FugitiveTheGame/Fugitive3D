extends HBoxContainer
class_name PlayerLegendEntry

export(NodePath) var colorPath: NodePath
onready var colorEntryControl := get_node(colorPath) as ColorRect

export(NodePath) var labelPath: NodePath
onready var labelNameControl := get_node(labelPath) as Label

var colorChosen: Color
var playerDataChosen: PlayerData

func initialize(playerData: PlayerData, color: Color):
	colorChosen = color
	playerDataChosen = playerData

func _ready():
	colorEntryControl.color = colorChosen
	labelNameControl.text = playerDataChosen.get_name()
