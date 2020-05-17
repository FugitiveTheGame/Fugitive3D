extends WindowDialog


export(NodePath) var tabsContainerPath: NodePath
onready var tabsContainer := get_node(tabsContainerPath) as TabContainer

export(NodePath) var modeSelectContainerPath: NodePath
onready var modeSelectContainer := get_node(modeSelectContainerPath) as Control

export(NodePath) var modeSelectButtonPath: NodePath
onready var modeSelectButton := get_node(modeSelectButtonPath) as OptionButton

export(NodePath) var rulesTextboxPath: NodePath
onready var rulesTextbox := get_node(rulesTextboxPath) as RichTextLabel

export(NodePath) var controlsTextboxPath: NodePath
onready var controlsTextbox := get_node(controlsTextboxPath) as RichTextLabel

var showGameMode = null
var showControlsFirst := false

func load_modes():
	# Populate the mode drop down
	modeSelectButton.clear()
	
	var ii := 0
	for modeId in Maps.modes:
		modeSelectButton.add_item(modeId)
		# Select the requested mode
		if modeId == showGameMode:
			modeSelectButton.selected = ii
		ii += 1
	
	# No mode was selected, just select the first
	if modeSelectButton.selected < 0:
		modeSelectButton.selected = 0


func load_mode_data(modeId: String):
	var mode = Maps.modes[modeId]
	
	var rulesPath = mode[Maps.MODE_RULES]
	
	var controlsObj = mode[Maps.MODE_CONTROLS]
	var controlsPath: String
	var platformCategory := PlatformTypeUtils.get_platform_category()
	match platformCategory:
		PlatformTypeUtils.PlatformCategory.Flat:
			if PlatformTypeUtils.get_platform_type() == PlatformTypeUtils.PlatformType.FlatMobile:
				controlsPath = controlsObj[Maps.MODE_CONTROLS_FLAT_MOBILE]
			else:
				controlsPath = controlsObj[Maps.MODE_CONTROLS_FLAT]
		PlatformTypeUtils.PlatformCategory.Vr:
			controlsPath = controlsObj[Maps.MODE_CONTROLS_VR]
	
	rulesTextbox.bbcode_text = read_text(rulesPath)
	controlsTextbox.bbcode_text = read_text(controlsPath)


func read_text(path: String) -> String:
	var file = File.new()
	if file.open(path, File.READ) != 0:
		print("Error opening file")
		return "null"
	
	var text = file.get_as_text()
	file.close()
	
	return text


func _on_HelpDialog_about_to_show():
	load_modes()
	
	if showGameMode == null:
		modeSelectContainer.show()
	else:
		modeSelectContainer.hide()
	
	if showControlsFirst:
		tabsContainer.current_tab = 1
	
	var modeId := modeSelectButton.get_item_text(modeSelectButton.selected)
	load_mode_data(modeId)


func _on_ModeSelectButton_item_selected(id):
	var modeId := modeSelectButton.get_item_text(id)
	load_mode_data(modeId)
