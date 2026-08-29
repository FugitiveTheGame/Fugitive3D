extends CharacterBody3D

signal return_to_main_menu

@onready var camera := $Camera3D as FpsCamera
@onready var player := $Player as Player

func get_player() -> Player:
	return player

var update_threshold := Threshold.new(Utils.COMMON_NETWORK_UPDATE_THRESHOLD)

@export var Sensitivity_X := 0.01
@export var TouchSensitivity_X := 0.1
@export var Sensitivity_Y := 0.005
@export var Invert_Y_Axis := false
@export var Maximum_Y_Look := 45
@export var Crouch_Accelaration := 1.0
@export var Walk_Accelaration := 3.0
@export var Sprint_Accelaration := 5.0
@export var Jump_Speed := 10.0
@export var Gravity := pow(9.8, 2)
@export var CameraIsCurrentOnStart: bool = true

@export var virtual_joysticks_path: NodePath
@onready var virtual_joysticks := get_node(virtual_joysticks_path) as VirtualJoysticks

@export var inGameMenuPath: NodePath
@onready var inGameMenu := get_node(inGameMenuPath) as Window

@export var exitGameHudPath: NodePath
@onready var exitGameHud := get_node(exitGameHudPath) as Control

@export var helpDialogPath: NodePath
@onready var helpDialog := get_node(helpDialogPath) as Window

var mouseLookSensetivityModifier := 1.0

# Our velocity vector never seems to be exactly zero.
# So any velocity under this threshold will be considered no moving
const MOVEMENT_LAMBDA := 0.01

var allowMovement := true


@export var HeldObjectPath: NodePath
var heldObject: Node3D: get = held_object_get, set = held_object_set
func held_object_set(value: Node3D):
	heldObject = value
	self.camera.heldObject = self.heldObject
func held_object_get() -> Node3D:
	return heldObject

@export var crouch_button_path: NodePath
@onready var crouch_button := get_node(crouch_button_path) as TouchScreenButton

@export var sprint_button_path: NodePath
@onready var sprint_button := get_node(sprint_button_path) as TouchScreenButton


func mouse_captured() -> bool:
	return Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

var Movement_Speed := 0.0


func _ready():
	player.set_is_local_player()
	
	self.heldObject = get_node_or_null(HeldObjectPath)
	
	if not DisplayServer.is_touchscreen_available():
		capture_mouse()
	
	self.camera.current = CameraIsCurrentOnStart
	update_camera_to_head()
	
	mouseLookSensetivityModifier = UserData.data.flat_mouse_sensetivity


func _process(delta):
	########################################
	# Handle input for gameplay purposes
	player.sprint = Input.is_action_pressed("flat_player_sprint")
	
	if virtual_joysticks.right_output.x != 0.0:
		var x := virtual_joysticks.right_output.x
		# y=\frac{x^{6}}{x}
		rotate_y(((pow(x, 6.0)/x) * -TouchSensitivity_X) * mouseLookSensetivityModifier)
	
	var look_x_joystick := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	if abs(look_x_joystick) > 0.1 and mouse_captured():
		rotate_y(-Sensitivity_X * mouseLookSensetivityModifier * look_x_joystick)


func _physics_process(delta):
	player.velocity.x = 0
	player.velocity.z = 0
	player.velocity.y -= Gravity * delta
	
	var Accelaration: float
	var Maximum_Speed: float
	
	if player.is_sprinting():
		Accelaration = Sprint_Accelaration
		Maximum_Speed = player.speed_sprint
	elif player.is_crouching:
		Accelaration = Crouch_Accelaration
		Maximum_Speed = player.speed_crouch
	else:
		Accelaration = Walk_Accelaration
		Maximum_Speed = player.speed_walk
	
	if Input.is_action_pressed("flat_player_up") or virtual_joysticks.left_output.y > 0.0:
		Movement_Speed += Accelaration
		if Movement_Speed > Maximum_Speed:
			Movement_Speed = Maximum_Speed
		player.velocity.x += -global_transform.basis.z.x * Movement_Speed
		player.velocity.z += -global_transform.basis.z.z * Movement_Speed
	elif Input.is_action_pressed("flat_player_down") or virtual_joysticks.left_output.y < 0.0:
		Movement_Speed += Accelaration
		if Movement_Speed > Maximum_Speed:
			Movement_Speed = Maximum_Speed
		player.velocity.x += global_transform.basis.z.x * Movement_Speed
		player.velocity.z += global_transform.basis.z.z * Movement_Speed
	
	if Input.is_action_pressed("flat_player_left") or virtual_joysticks.left_output.x < 0.0:
		Movement_Speed += Accelaration
		if Movement_Speed > Maximum_Speed:
			Movement_Speed = Maximum_Speed
		player.velocity.x += -global_transform.basis.x.x * Movement_Speed
		player.velocity.z += -global_transform.basis.x.z * Movement_Speed
	elif Input.is_action_pressed("flat_player_right") or virtual_joysticks.left_output.x > 0.0:
		Movement_Speed += Accelaration
		if Movement_Speed > Maximum_Speed:
			Movement_Speed = Maximum_Speed
		player.velocity.x += global_transform.basis.x.x * Movement_Speed
		player.velocity.z += global_transform.basis.x.z * Movement_Speed
	
	if DisplayServer.is_touchscreen_available():
		if virtual_joysticks.left_output.y == 0.0 and virtual_joysticks.left_output.x == 0.0:
			player.velocity.x = 0
			player.velocity.z = 0
	else:
		if not(Input.is_action_pressed("flat_player_up") or Input.is_action_pressed("flat_player_down") or Input.is_action_pressed("flat_player_left") or Input.is_action_pressed("flat_player_right")):
			player.velocity.x = 0
			player.velocity.z = 0
	
	if is_on_floor():
		if Input.is_action_just_pressed("flat_player_jump"):
			if player.stamina >= player.JUMP_STAMINA_COST:
				player.stamina -= player.JUMP_STAMINA_COST
				player.velocity.y = Jump_Speed
				
				player.jump()
			else:
				player.out_of_stamina()
			
	
	if not allowMovement:
		player.velocity = Vector3()
	
	set_velocity(player.velocity)
	set_up_direction(Vector3(0.0, 1.0, 0.0))
	move_and_slide()
	player.velocity = velocity
	
	# Gravity means that even when we're on the ground, our Y component always
	# has a large size. So for isMoving we only consider X and Z
	player.isMoving = (Vector3(player.velocity.x, 0.0, player.velocity.z).length() > MOVEMENT_LAMBDA) and allowMovement
	
	if not player.gameEnded and update_threshold.is_exceeded():
		player.rpc("network_update", position, rotation, player.velocity, player.is_crouching, player.isMoving, player.sprint, player.stamina)


func trigger_menu():
	if not inGameMenu.visible:
			inGameMenu.popup_centered()
	else:
		inGameMenu.hide()


func _input(event):
	if event.is_action_released("flat_player_exit"):
		trigger_menu()
	
	# Don't process input if we aren't capturing the mouse
	if event is InputEventMouseMotion and mouse_captured():
		rotate_y(-Sensitivity_X * mouseLookSensetivityModifier * event.relative.x)
	else:
		if player.car == null:
			if event.is_action_pressed("flat_player_crouch"):
				if player != null:
					player.is_crouching = true
					update_camera_to_head()
			elif event.is_action_released("flat_player_crouch"):
				if player != null:
					player.is_crouching = false
					update_camera_to_head()


func _notification(what):
	if is_inside_tree():
		if what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			capture_mouse()
		elif what == MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			release_mouse()
		elif what == NOTIFICATION_WM_GO_BACK_REQUEST: 
			trigger_menu()


func update_camera_to_head():
	var shape = player.get_current_shape()
	var global = shape.head.global_transform.origin
	var local = to_local(global)
	
	camera.position.y = local.y


func _on_CrouchButton_released():
	if player.car == null:
		player.is_crouching = not player.is_crouching
		update_camera_to_head()


func _on_ExitGameHud_return_to_main_menu():
	emit_signal("return_to_main_menu")


func _on_ExitGameHud_on_exit_dialog_show():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_ExitGameHud_on_exit_dialog_hide():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_InGameMenuHud_about_to_show():
	exitGameHud.hide()
	helpDialog.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_InGameMenuHud_popup_hide():
	# Connected to visibility_changed, which also fires on show
	if inGameMenu.visible:
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_InGameMenuHud_show_exit():
	exitGameHud.show_dialog()


func _on_InGameMenuHud_show_help():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	var mapId = GameData.general[GameData.GENERAL_MAP]
	var mode := Maps.get_mode_for_map(mapId)
	helpDialog.showGameMode = mode[Maps.MODE_NAME]
	helpDialog.showControlsFirst = true
	helpDialog.popup_centered()


func _on_HelpDialog_about_to_show():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_HelpDialog_popup_hide():
	if helpDialog.visible:
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_InGameMenuHud_resume_game():
	pass # Replace with function body.
