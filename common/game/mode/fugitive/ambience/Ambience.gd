extends Spatial


var effects := []

func _ready():
	for child in get_children():
		if child is AmbientEffect:
			effects.push_back(child);
	
	if GameData.currentGame != null:
		GameData.currentGame.connect("preconfigure_complete", self, "on_game_configuration_complete")


func on_game_configuration_complete():
	var localPlayer := GameData.currentGame.localPlayer
	
	for effect in effects:
		effect.initialize_effect(localPlayer)


func calculate_bounding_box(roads) -> AABB:
	var bb := AABB()
	
	for road in roads:
		var colShape = road.get_node("CollisionShape")
		var aabb := Utils.aabb_from_shape(colShape)
		bb = bb.merge(aabb)
	
	return bb


func get_effects_position():
	if GameData.currentGame != null and GameData.currentGame.localPlayer != null:
		return to_local(GameData.currentGame.localPlayer.global_transform.origin)
	else:
		return null


func _physics_process(delta):
	var effect_position = get_effects_position()
	if effect_position != null:
		for effect in effects:
			var chance := randf()
			if chance < effect.frequency:
				effect.play(effect_position)
