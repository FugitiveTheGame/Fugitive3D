extends VBoxContainer
class_name PlayerLegendEntry

@export var colorPath: NodePath
@onready var colorEntryControl := get_node(colorPath) as ColorRect

@export var labelPath: NodePath
@onready var labelNameControl := get_node(labelPath) as Label

@export var crouchPath: NodePath
@onready var crouchControl := get_node(crouchPath) as TextureRect

@export var frozenPath: NodePath
@onready var frozenControl := get_node(frozenPath) as TextureRect

@export var staminaBarPath: NodePath
@onready var staminaBar := get_node(staminaBarPath) as ProgressBar


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


func populate(data, nextData, weight):
	frozenControl.visible = data.frozen
	crouchControl.visible = data.isCrouching
	staminaBar.value = lerp(data.stamina, nextData.stamina, weight)
