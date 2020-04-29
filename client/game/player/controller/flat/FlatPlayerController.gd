extends KinematicBody

signal return_to_main_menu

onready var camera := $Camera as FpsCamera
onready var player := $Player as Player

func get_player() -> Player:
	return player


export(float) var Sensitivity_X := 0.01
export(float) var Sensitivity_Y := 0.005
export(bool) var Invert_Y_Axis := false
export(float) var Maximum_Y_Look := 45
export(float) var Crouch_Accelaration := 1.0
export(float) var Walk_Accelaration := 3.0
export(float) var Sprint_Accelaration := 6.0
export(float) var Jump_Speed := 10.0
export(float) var Gravity := pow(9.8, 2)
export(bool) var CameraIsCurrentOnStart: bool = true

var mouseLookSensetivityModifier := 1.0

# Our velocity vector never seems to be exactly zero.
# So any velocity under this threshold will be considered no moving
const MOVEMENT_LAMBDA := 0.01

var allowMovement := true

export(NodePath) var HeldObjectPath: NodePath
var heldObject: Spatial setget held_object_set, held_object_get
func held_object_set(value: Spatial):
	heldObject = value
	self.camera.heldObject = self.heldObject
func held_object_get() -> Spatial:
	return heldObject

func mouse_captured() -> bool:
	return Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED

func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


var velocity := Vector3(0,0,0)
var forward_velocity := 0.0
var Movement_Speed := 0.0


func _ready():
	player.set_is_local_player()
	
	self.heldObject = get_node_or_null(HeldObjectPath)
	
	if not OS.has_touchscreen_ui_hint():
		capture_mouse()
	
	self.camera.current = CameraIsCurrentOnStart
	forward_velocity = Movement_Speed
	update_camera_to_head()
	
	mouseLookSensetivityModifier = UserData.data.flat_mouse_sensetivity


func _process(delta):
	########################################
	# Handle input for gameplay purposes
	player.isSprinting = Input.is_action_pressed("flat_player_sprint")


func _physics_process(delta):
	velocity.x = 0
	velocity.z = 0
	velocity.y -= Gravity * delta

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
	
	if Input.is_action_pressed("flat_player_up"):
		Movement_Speed += Accelaration
		if Movement_Speed > Maximum_Speed:
			Movement_Speed = Maximum_Speed
		velocity.x += -global_transform.basis.z.x * Movement_Speed
		velocity.z += -global_transform.basis.z.z * Movement_Speed
	elif Input.is_action_pressed("flat_player_down"):
		Movement_Speed += Accelaration
		if Movement_Speed > Maximum_Speed:
			Movement_Speed = Maximum_Speed
		velocity.x += global_transform.basis.z.x * Movement_Speed
		velocity.z += global_transform.basis.z.z * Movement_Speed
	
	if Input.is_action_pressed("flat_player_left"):
		Movement_Speed += Accelaration
		if Movement_Speed > Maximum_Speed:
			Movement_Speed = Maximum_Speed
		velocity.x += -global_transform.basis.x.x * Movement_Speed
		velocity.z += -global_transform.basis.x.z * Movement_Speed
	elif Input.is_action_pressed("flat_player_right"):
		Movement_Speed += Accelaration
		if Movement_Speed > Maximum_Speed:
			Movement_Speed = Maximum_Speed
		velocity.x += global_transform.basis.x.x * Movement_Speed
		velocity.z += global_transform.basis.x.z * Movement_Speed
		
	if not(Input.is_action_pressed("flat_player_up") or Input.is_action_pressed("flat_player_down") or Input.is_action_pressed("flat_player_left") or Input.is_action_pressed("flat_player_right")):
		velocity.x = 0
		velocity.z = 0
	
	if is_on_floor():
		if Input.is_action_just_pressed("flat_player_jump") and player.stamina >= player.JUMP_STAMINA_COST:
			player.stamina -= player.JUMP_STAMINA_COST
			
			velocity.y = Jump_Speed
	
	if not allowMovement:
		velocity = Vector3()
	
	velocity = move_and_slide(velocity, Vector3(0.0, 1.0, 0.0))
	
	# Gravity means that even when we're on the ground, our Y component always
	# has a large size. So for isMoving we only consider X and Z
	player.isMoving = (abs(Vector3(velocity.x, 0.0, velocity.z).length()) > MOVEMENT_LAMBDA)
	
	player.rpc_unreliable("network_update", translation, rotation, player.is_crouching, player.isMoving, player.isSprinting)


func _input(event):
	# Don't process input if we aren't capturing the mouse
	if not mouse_captured():
		return
	
	if event.is_action_released("flat_player_exit"):
		$HudCanvas/HudContainer/ExitGameHud.show_dialog()
	
	if event is InputEventMouseMotion:
		rotate_y(-Sensitivity_X * mouseLookSensetivityModifier * event.relative.x)
	else:
		if player.car == null:
			if event.is_action_pressed("flat_player_crouch", true):
				if player != null:
					player.is_crouching = true
					update_camera_to_head()
			elif event.is_action_released("flat_player_crouch"):
				if player != null:
					player.is_crouching = false
					update_camera_to_head()


func _notification(what):
	if is_inside_tree():
		if what == MainLoop.NOTIFICATION_WM_FOCUS_IN:
			capture_mouse()
		elif what == MainLoop.NOTIFICATION_WM_FOCUS_OUT:
			release_mouse()


func update_camera_to_head():
	var shape = player.get_current_shape()
	var global = shape.head.global_transform.origin
	var local = to_local(global)
	
	camera.translation.y = local.y


func _on_ExitGameHud_return_to_main_menu():
	emit_signal("return_to_main_menu")


func _on_ExitGameHud_on_exit_dialog_show():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_ExitGameHud_on_exit_dialog_hide():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
