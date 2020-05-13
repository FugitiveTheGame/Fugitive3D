extends "res://addons/OQ_Toolkit/OQ_ARVROrigin/scripts/OQ_ARVROrigin.gd"

signal return_to_main_menu

var standingHeight: float = -1.0
const CROUCH_THRESHOLD := 0.75

onready var camera := $OQ_ARVRCamera
onready var player := $Player as Player
onready var locomotion := $Locomotion_Stick
onready var hudCanvas := $OQ_LeftController/VisibilityToggle/HudCanvas
onready var hudVisibilityToggle := $OQ_LeftController/VisibilityToggle
onready var hud := $OQ_LeftController/VisibilityToggle/HudCanvas.find_node("HudContainer", true, false) as Control
onready var fpsLabel := $OQ_LeftController/VisibilityToggle/HudCanvas.find_node("FpsLabel", true, false) as Label
onready var uiRaycast := $OQ_RightController/Feature_UIRayCast
onready var exitGameHud := hud.find_node("ExitGameHud", true, false)

const DEBOUNCE_THRESHOLD_MS := 100
var debounceBookKeeping = {}
func debounced_button_just_released(button_id) -> bool:
	var debouncedReleased: bool
	
	var justReleased = vr.button_just_released(button_id)
	if justReleased:
		if debounceBookKeeping.has(button_id):
			var lastPressed = debounceBookKeeping[button_id] as int
			var delta = OS.get_system_time_msecs() - lastPressed
			# Debounce and throw away this release
			if delta < DEBOUNCE_THRESHOLD_MS:
				debouncedReleased = false
				print("Debounced")
			else:
				debounceBookKeeping[button_id] = OS.get_system_time_msecs()
				debouncedReleased = true
				print("new justRelease")
		else:
			debounceBookKeeping[button_id] = OS.get_system_time_msecs()
			debouncedReleased = true
			print("first justRelease")
	else:
		debouncedReleased = false
	
	return debouncedReleased


func _ready():
	player.set_is_local_player()
	
	# Performance tuning for mobile VR clients
	if OS.has_feature("mobile"):
		camera.far = 100.0
		hudCanvas.transparent = false
	
	fpsLabel.visible = OS.is_debug_build()


func set_standing_height():
	# Only allow setting standing height during pre-game
	# Other wise you could cheat during the game
	if not player.gameStarted:
		vr.log_info("Standing height set")
		standingHeight = vr.get_current_player_height()
		
		hud.find_node("HeightLabel", true, false).text = "Height: %f m" % standingHeight
	else:
		vr.log_warning("Cannot set standing height while playing")


func _process(delta):
	var curHeight = camera.translation.y
	var curPercent = curHeight / standingHeight
	
	# If the player's is different enough, consider them crouching
	if curHeight < standingHeight and curPercent < CROUCH_THRESHOLD:
		player.is_crouching = true
	else:
		player.is_crouching = false
	
	# Handle VR controller input
	if debounced_button_just_released(vr.BUTTON.B):
		set_standing_height()
	
	if debounced_button_just_released(vr.BUTTON.ENTER):
		hudVisibilityToggle.visible = true
		exitGameHud.show_dialog()
	
	player.sprint = vr.button_pressed(vr.BUTTON.A)
	player.isMoving = locomotion.is_moving
	
	if player.is_sprinting():
		locomotion.move_speed = player.speed_sprint
	elif player.is_crouching:
		locomotion.move_speed = player.speed_crouch
	else:
		locomotion.move_speed = player.speed_walk


func _physics_process(delta):
	var totalTranslation = translation
	
	# We need to incorporate head turn into our network rotation
	var totalRotation = rotation
	totalRotation.y += camera.rotation.y
	
	if not player.gameEnded:
		player.rpc_unreliable("network_update", totalTranslation, totalRotation, Vector3(), player.is_crouching, player.isMoving, player.sprint, player.stamina)
	
	if fpsLabel.visible:
		var fps := Engine.get_frames_per_second()
		fpsLabel.text = ("%d fps" % fps)


func _on_ExitGameHud_return_to_main_menu():
	emit_signal("return_to_main_menu")


func _on_ExitGameHud_on_exit_dialog_show():
	uiRaycast.show()


func _on_ExitGameHud_on_exit_dialog_hide():
	uiRaycast.hide()
