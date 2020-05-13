extends Sprite3D
class_name Label3D

export(String) var text := "I am a Label" setget set_text


export(int) var margin := 16;
export(float) var font_size_multiplier := 1.0

enum ResizeModes {AUTO_RESIZE, FIXED}
export (ResizeModes) var resize_mode := ResizeModes.AUTO_RESIZE

onready var ui_label : Label = $Viewport/CenterContainer/Label
onready var ui_container : CenterContainer = $Viewport/CenterContainer
onready var ui_viewport : Viewport = $Viewport


func _ready():
	if OS.has_feature("mobile"):
		# This is a big perf hit on mobile
		ui_viewport.transparent_bg = false
	
	texture = ui_viewport.get_texture()
	update_label()


func resize_auto():
	var size = ui_label.get_minimum_size();
	var res = Vector2(size.x + margin * 2, size.y + margin * 2)
	
	ui_container.set_size(res)
	ui_viewport.set_size(res)


func resize_fixed():
	# resize container and viewport while parent and mesh stay fixed
	var parent_width = scale.x
	var parent_height = scale.y
	
	var new_size = Vector2(parent_width * 1024 / font_size_multiplier, parent_height * 1024 / font_size_multiplier)
	
	ui_viewport.set_size(new_size)
	ui_container.set_size(new_size)


func set_text(value: String):
	text = value
	update_label()


func update_label():
	if (!ui_label): return;
	ui_label.set_text(text);
	
	match resize_mode:
		ResizeModes.AUTO_RESIZE:
			resize_auto();
		ResizeModes.FIXED:
			resize_fixed();
