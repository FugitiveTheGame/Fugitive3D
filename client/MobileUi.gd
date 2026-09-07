extends Node

# Layout and scaling for the touchscreen client.
#
# Phones report far more pixels than the flat UI was drawn against, so the 2D
# canvas is scaled to a fixed design height here and every other bit of layout
# works in those design units. Safe area insets are reported in the same units
# so callers never have to think about device pixels.

# Design height used on touchscreens. Smaller than the height the scenes are
# authored against, so a control drawn at 39 units covers more of a phone
# screen than of a monitor.
const TOUCH_DESIGN_HEIGHT := 540.0

# Text is read at arm's length on a phone rather than at desk distance
const TOUCH_FONT_SIZE := 20

# Every screen edge keeps at least this much clearance, in design units, even
# where the platform reports no cutout of its own
const MIN_EDGE_MARGIN := 16.0

# Touch control sizes, as a fraction of the design height, so a thumb covers
# the same slice of any screen
const STICK_DIAMETER_RATIO := 0.28
const TOUCH_BUTTON_HEIGHT_RATIO := 0.13
const TOUCH_GAP_RATIO := 0.03

const BASE_OFFSETS_META := &"mobile_ui_base_offsets"

# Emitted after the design space changes size, so placement can be redone
signal layout_changed

var is_touch_ui := false


func _ready() -> void:
	# Standing in for a screen the desktop does not have, so the phone layout can
	# be looked at without deploying to one
	if is_forced():
		Input.set_emulate_touch_from_mouse(true)
	
	is_touch_ui = detect_touch_ui()
	if not is_touch_ui:
		return
	
	print("Touch UI enabled")
	apply_content_scale()
	apply_touch_theme()
	get_window().size_changed.connect(_on_window_size_changed)


static func is_forced() -> bool:
	return "--touch-ui" in OS.get_cmdline_args() or "--touch-ui" in OS.get_cmdline_user_args()


func detect_touch_ui() -> bool:
	if not DisplayServer.is_touchscreen_available():
		return false
	
	if is_forced():
		return true
	
	return PlatformTypeUtils.get_platform_type() == PlatformTypeUtils.PlatformType.FlatMobile


func _on_window_size_changed() -> void:
	layout_changed.emit()


# The project already scales the canvas against its authored size. Phones only
# need it pinned to a known height and magnified, so the touch control ratios
# below mean the same thing on every device.
func apply_content_scale() -> void:
	var window := get_window()
	var authored := window.content_scale_size.y
	if authored <= 0:
		return
	
	window.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP_HEIGHT
	window.content_scale_factor = authored / TOUCH_DESIGN_HEIGHT


func apply_touch_theme() -> void:
	var theme_path := str(ProjectSettings.get_setting("gui/theme/custom", ""))
	if theme_path.is_empty():
		return
	
	# The project theme is a shared cached resource, so every control that uses
	# it picks the larger text up
	var theme := load(theme_path) as Theme
	if theme == null:
		return
	
	theme.default_font_size = TOUCH_FONT_SIZE


# The 2D canvas size, in design units
func design_size() -> Vector2:
	return get_window().get_visible_rect().size


# The part of the design space that is clear of cutouts and screen edges
func safe_area() -> Rect2:
	var full := Rect2(Vector2.ZERO, design_size())
	var native := Vector2(get_window().size)
	if not is_touch_ui or native.x <= 0.0 or native.y <= 0.0:
		return full.grow(-MIN_EDGE_MARGIN)
	
	# Reported against the screen, so it has to come back to the window first
	var reported := Rect2(DisplayServer.get_display_safe_area())
	reported.position -= Vector2(DisplayServer.window_get_position())
	if reported.get_area() <= 0.0:
		return full.grow(-MIN_EDGE_MARGIN)
	
	var to_design := full.size / native
	var safe := Rect2(reported.position * to_design, reported.size * to_design)
	
	# Platforms with nothing to avoid report the whole screen
	return full.intersection(safe).grow(-MIN_EDGE_MARGIN)


# Pulls a whole menu in from the screen edges and keeps it there. Offsets
# authored in the scene are preserved and added to the inset. Backdrops are
# left alone and popups place themselves, so only edge-anchored panels move.
func keep_menu_inside_safe_area(root: Control) -> void:
	if not is_touch_ui:
		return
	
	# A minimum authored for a monitor does not fit a phone, and holding to it
	# would push everything anchored to the bottom off screen
	root.custom_minimum_size = Vector2.ZERO
	
	var panels: Array = []
	for child in root.get_children():
		if child is Control and not child is SubViewportContainer:
			panels.append(child)
	
	var apply := func():
		for panel in panels:
			inset_to_safe_area(panel)
	apply.call()
	
	layout_changed.connect(apply)
	# This autoload outlives the menu, so the hook has to leave with it
	root.tree_exiting.connect(func(): layout_changed.disconnect(apply))
	
	keep_popups_inside_safe_area(root)


# Dialogs are sized for a monitor, so on a phone they have to be brought back
# inside the safe area or their title bar and buttons end up off screen
func keep_popups_inside_safe_area(root: Node) -> void:
	if not is_touch_ui:
		return
	
	for window in find_windows(root):
		window.visibility_changed.connect(fit_popup.bind(window))


static func find_windows(root: Node) -> Array:
	var found: Array = []
	for child in root.get_children():
		if child is Window:
			found.append(child)
		found.append_array(find_windows(child))
	return found


func fit_popup(window: Window) -> void:
	if not is_instance_valid(window) or not window.visible:
		return
	
	var area := safe_area()
	# The title bar is drawn above the window's own rect
	var title := float(window.get_theme_constant("title_height", "Window"))
	var room := Vector2(area.size.x, area.size.y - title)
	
	window.size = Vector2i(minf(window.size.x, room.x), minf(window.size.y, room.y))
	
	var top_left := area.get_center() - Vector2(window.size) / 2.0
	top_left.x = clampf(top_left.x, area.position.x, area.end.x - window.size.x)
	top_left.y = clampf(top_left.y, area.position.y + title, area.end.y - window.size.y)
	window.position = Vector2i(top_left)


func inset_to_safe_area(control: Control) -> void:
	if control == null or not is_instance_valid(control):
		return
	
	var base: Vector4
	if control.has_meta(BASE_OFFSETS_META):
		base = control.get_meta(BASE_OFFSETS_META)
	else:
		base = Vector4(control.offset_left, control.offset_top, control.offset_right, control.offset_bottom)
		control.set_meta(BASE_OFFSETS_META, base)
	
	var area := safe_area()
	var full := design_size()
	
	var left_inset := area.position.x
	var right_inset := full.x - area.end.x
	var top_inset := area.position.y
	var bottom_inset := full.y - area.end.y
	
	control.offset_left = base.x + shift(left_inset, right_inset, control.anchor_left)
	control.offset_top = base.y + shift(top_inset, bottom_inset, control.anchor_top)
	control.offset_right = base.z + shift(left_inset, right_inset, control.anchor_right)
	control.offset_bottom = base.w + shift(top_inset, bottom_inset, control.anchor_bottom)


# An offset hanging off an anchor moves in from whichever edge that anchor
# sits against, and not at all when it is anchored to the middle
static func shift(near_inset: float, far_inset: float, anchor: float) -> float:
	return near_inset * (1.0 - anchor) - far_inset * anchor


# Width and height of a joystick's base, in design units
func stick_diameter() -> float:
	return design_size().y * STICK_DIAMETER_RATIO


func touch_button_height() -> float:
	return design_size().y * TOUCH_BUTTON_HEIGHT_RATIO


func touch_gap() -> float:
	return design_size().y * TOUCH_GAP_RATIO
