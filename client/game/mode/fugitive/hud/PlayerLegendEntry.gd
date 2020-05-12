extends VBoxContainer
class_name PlayerLegendEntry

export(NodePath) var colorPath: NodePath
onready var colorEntryControl := get_node(colorPath) as ColorRect

export(NodePath) var labelPath: NodePath
onready var labelNameControl := get_node(labelPath) as Label

export(NodePath) var crouchPath: NodePath
onready var crouchControl := get_node(crouchPath) as TextureRect

export(NodePath) var frozenPath: NodePath
onready var frozenControl := get_node(frozenPath) as TextureRect

export(NodePath) var staminaBarPath: NodePath
onready var staminaBar := get_node(staminaBarPath) as ProgressBar


var colorChosen: Color
var playerDataChosen: PlayerData

func initialize(playerData: PlayerData, color: Color):
	colorChosen = color
	playerDataChosen = playerData


func _ready():
	colorEntryControl.color = colorChosen
	labelNameControl.text = playerDataChosen.get_name()
	
	frozenControl.hide()
	crouchControl.hide()


func populate(data):
	frozenControl.visible = data.frozen
	crouchControl.visible = data.isCrouching
	staminaBar.value = data.stamina
	print(data.stamina)
