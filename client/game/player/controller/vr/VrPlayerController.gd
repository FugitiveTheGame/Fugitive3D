extends XROrigin3D

signal return_to_main_menu

var standingHeight: float = -1.0
const CROUCH_THRESHOLD := 0.75

@onready var camera := $Camera as XRCamera3D
@onready var player := $Player as Player
@onready var locomotion := $Locomotion
@onready var hudCanvas := $LeftHand/VisibilityToggle/HudCanvas
@onready var hudVisibilityToggle := $LeftHand/VisibilityToggle
@onready var hud := $LeftHand/VisibilityToggle/HudCanvas.find_child("HudContainer", true, false) as Control
@onready var fpsLabel := $LeftHand/VisibilityToggle/HudCanvas.find_child("FpsLabel", true, false) as Label
@onready var uiRaycast := $RightHand/UiRaycast
@onready var playerCollision := $PlayerBody as XRToolsPlayerBody

@onready var inGameMenuHud := hud.find_child("InGameMenuHud", true, false) as Window
@onready var exitGameHud := hud.find_child("ExitGameHud", true, false) as ConfirmationDialog
@onready var helpDialog := hud.find_child("HelpDialog", true, false) as Window

var update_threshold := Threshold.new(Utils.COMMON_NETWORK_UPDATE_THRESHOLD)

const seated_crouching_offset_meters := 0.45
var is_standing := true

# While fixed (seated in a car) the body stops simulating and the game code
# drives the origin transform directly
var is_fixed := false:
	set(value):
		is_fixed = value
		if not value:
			sync_body_to_rig()
		playerCollision.enabled = not value

const CENTER_MIN := 0.20
const CENTER_MAX := 0.40
@onready var centerLabel := $Camera/CenterLabel
@onready var centerIndicator := $PlayerBody/CenterIndicator as CSGPrimitive3D
@onready var centerIndicatorMaterial := centerIndicator.material as StandardMaterial3D


const DEBOUNCE_THRESHOLD_MS := 100
var debounceBookKeeping = {}
func debounced_button_just_released(button_id) -> bool:
	var debouncedReleased: bool

	var justReleased = vr.button_just_released(button_id)
	if justReleased:
		if debounceBookKeeping.has(button_id):
			var lastPressed = debounceBookKeeping[button_id] as int
			var delta = Time.get_ticks_msec() - lastPressed
			# Debounce and throw away this release
			if delta < DEBOUNCE_THRESHOLD_MS:
				debouncedReleased = false
			else:
				debounceBookKeeping[button_id] = Time.get_ticks_msec()
				debouncedReleased = true
		else:
			debounceBookKeeping[button_id] = Time.get_ticks_msec()
			debouncedReleased = true
	else:
		debouncedReleased = false

	return debouncedReleased


func _enter_tree():
	UserData.connect("user_data_updated", Callable(self, "on_user_data_updated"))


func _ready():
	vr.register_rig(self, camera, $LeftHand, $RightHand)

	player.set_is_local_player()

	# Performance tuning for mobile VR clients
	if OS.has_feature("mobile"):
		camera.far = 100.0

	fpsLabel.visible = OS.is_debug_build()

	call_deferred("sync_body_to_rig")
	call_deferred("update_standing")


# The xr-tools PlayerBody snapshots the rig position in its own _ready() and
# then runs top level, but the game positions the controller after add_child().
# Without this re-sync the body stays behind at the world origin and drags the
# view up through the map.
func sync_body_to_rig():
	playerCollision.global_transform = global_transform


func _exit_tree():
	UserData.disconnect("user_data_updated", Callable(self, "on_user_data_updated"))
	vr.unregister_rig(self)


func set_standing_height():
	# Only allow setting standing height during pre-game
	# Other wise you could cheat during the game
	if not player.gameStarted:
		vr.log_info("Standing height set")
		standingHeight = vr.get_current_player_height()

		hud.find_child("HeightLabel", true, false).text = "Height: %f m" % standingHeight
	else:
		vr.log_warning("Cannot set standing height while playing")


func process_crouch():
	# Standing mode, crouching is just real crouching
	if is_standing:
		# Movement input
		var curHeight = camera.position.y
		var curPercent = curHeight / standingHeight

		# If the player's is different enough, consider them crouching
		if (curHeight < standingHeight and curPercent < CROUCH_THRESHOLD) or player.car != null:
			player.is_crouching = true
		else:
			player.is_crouching = false
	# Seated mode, crouching is button controlled
	else:
		var wasCrouching := player.is_crouching
		player.is_crouching = vr.button_pressed(vr.BUTTON.LEFT_GRIP_TRIGGER)
		if wasCrouching != player.is_crouching:
			update_head_height()


func _process(delta):
	# Process what to show about the re-center indicator
	var camTrans := playerCollision.global_position - camera.global_position
	var distFromCenter := Vector2(camTrans.x, camTrans.z).length()

	centerLabel.visible = distFromCenter >= CENTER_MAX
	centerIndicator.visible = distFromCenter > CENTER_MIN

	var percentVisible := clampf((distFromCenter-CENTER_MIN)/(CENTER_MAX-CENTER_MIN), 0.0, 1.0)
	centerIndicatorMaterial.albedo_color.a = percentVisible


func inject_ptt_action(pressed: bool):
	var event := InputEventAction.new()
	event.action = "push_to_talk"
	event.pressed = pressed
	Input.parse_input_event(event)


func _physics_process(delta):
	# Handle crouching
	process_crouch()

	if vr.button_just_pressed(vr.BUTTON.RIGHT_THUMBSTICK):
		inject_ptt_action(true)
	elif debounced_button_just_released(vr.BUTTON.RIGHT_THUMBSTICK):
		inject_ptt_action(false)

	# Handle VR controller input
	if debounced_button_just_released(vr.BUTTON.B):
		set_standing_height()

	if debounced_button_just_released(vr.BUTTON.ENTER):
		hudVisibilityToggle.visible = true
		if inGameMenuHud.visible:
			inGameMenuHud.hide()
		else:
			inGameMenuHud.popup_centered()

	player.sprint = vr.button_pressed(vr.BUTTON.A)
	player.isMoving = locomotion.is_moving

	if player.is_sprinting():
		locomotion.move_speed = player.speed_sprint
	elif player.is_crouching:
		locomotion.move_speed = player.speed_crouch
	else:
		locomotion.move_speed = player.speed_walk

	if not player.gameEnded and update_threshold.is_exceeded():
		# Our network position is that of our collision body
		var totalTranslation = playerCollision.global_transform.origin
		totalTranslation.y -= totalTranslation.y - global_transform.origin.y

		# We need to incorporate head turn into our network rotation
		var totalRotation = rotation
		totalRotation.y += camera.rotation.y

		player.rpc("network_update", totalTranslation, totalRotation, Vector3(), player.is_crouching, player.isMoving, player.sprint, player.stamina)

	if fpsLabel.visible:
		var fps := Engine.get_frames_per_second()
		fpsLabel.text = ("%d fps" % fps)


func _on_InGameMenuHud_about_to_show():
	exitGameHud.hide()
	helpDialog.hide()

	uiRaycast.show()


func _on_InGameMenuHud_popup_hide():
	# Connected to visibility_changed, which also fires on show
	if inGameMenuHud.visible:
		return
	uiRaycast.hide()


func _on_ExitGameHud_return_to_main_menu():
	emit_signal("return_to_main_menu")


func _on_ExitGameHud_on_exit_dialog_show():
	uiRaycast.show()


func _on_ExitGameHud_on_exit_dialog_hide():
	uiRaycast.hide()


func _on_HelpDialog_about_to_show():
	uiRaycast.show()


func _on_HelpDialog_popup_hide():
	if helpDialog.visible:
		return
	uiRaycast.hide()


func _on_InGameMenuHud_show_exit():
	exitGameHud.popup_centered()


func _on_InGameMenuHud_show_help():
	var mapId = GameData.general[GameData.GENERAL_MAP]
	var mode := Maps.get_mode_for_map(mapId)
	helpDialog.showGameMode = mode[Maps.MODE_NAME]
	helpDialog.showControlsFirst = true

	helpDialog.popup_centered()


func on_user_data_updated():
	update_standing()


func update_standing():
	if UserData.data.vr_standing != is_standing:
		is_standing = UserData.data.vr_standing

		update_head_height()


func update_head_height():
	# A standing player maps 1:1. A seated headset sits at chair height, so the
	# body is pinned to a standing height instead of the measured head height.
	if is_standing:
		playerCollision.player_height_offset = 0.0
	else:
		playerCollision.calibrate_player_height()
		if player.is_crouching:
			playerCollision.player_height_offset -= seated_crouching_offset_meters
