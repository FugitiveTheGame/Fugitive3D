extends Spatial

onready var fpsLabel := $OQ_ARVROrigin/OQ_LeftController/OQ_VisibilityToggle/FpsLabel

func _process(delta):
	fpsLabel.set_label_text("%d fps" % Engine.get_frames_per_second())
