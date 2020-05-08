extends WindowDialog

export(NodePath) var rulesTextboxPath: NodePath
onready var rulesTextbox := get_node(rulesTextboxPath) as RichTextLabel

export(NodePath) var controlsTextboxPath: NodePath
onready var controlsTextbox := get_node(controlsTextboxPath) as RichTextLabel


func load_data():
	var mapId = GameData.general[GameData.GENERAL_MAP]
	var mode := Maps.get_mode_for_map(mapId)
	
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
	load_data()
