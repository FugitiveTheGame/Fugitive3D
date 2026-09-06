extends Node3D

var update_threshold := Threshold.new(Utils.COMMON_NETWORK_UPDATE_THRESHOLD)

var is_on := true
# Quest 2 can handle a few more lights, so we re-enable flashlights
@onready var is_quest2 := Utils.is_quest2()

func _ready():
	if Utils.renderer_is_gles2() and not is_quest2:
		$SpotLight3D.visible = false
		$LightBeam.alpha = 0.05
	else:
		$SpotLight3D.visible = true
		$LightBeam.alpha = 0.004


func toggle_on():
	GameAnalytics.design_event("toggle_flashlight")
	set_on(not is_on)


func set_on(on: bool):
	rpc("on_set_on", on)


@rpc("any_peer", "call_local") func on_set_on(on: bool):
	is_on = on
	
	if not Utils.renderer_is_gles2() or is_quest2:
		$SpotLight3D.visible = is_on
	
	$LightBeam.visible = is_on


@rpc("unreliable") func network_update(networkPosition: Vector3, networkRotation: Vector3):
	position = networkPosition
	rotation = networkRotation


func _physics_process(delta):
	if Utils.has_active_network_peer(multiplayer) and is_multiplayer_authority() and update_threshold.is_exceeded() and not GameData.currentGame.is_game_over():
		rpc("network_update", position, rotation)


func get_ray_caster():
	return $RayCast3D
