extends Spatial


export(NodePath) var fugitiveMapPath: NodePath
onready var fugitiveMap := get_node(fugitiveMapPath) as FugitiveMap


var boundingBox: AABB
var effects := []

func _ready():
	assert(fugitiveMap != null)
	boundingBox = calculate_bounding_box(fugitiveMap.get_roads())
	
	for child in get_children():
		if child is AmbientEffect:
			effects.push_back(child);


func calculate_bounding_box(roads) -> AABB:
	var bb := AABB()
	
	for road in roads:
		var colShape = road.get_node("CollisionShape")
		var aabb := Utils.aabb_from_shape(colShape)
		bb = bb.merge(aabb)
	
	return bb


func _physics_process(delta):
	
	var local_player_pos := to_local(GameData.currentGame.localPlayer.global_transform.origin)
	
	for effect in effects:
		var chance := randf()
		if chance < effect.frequency:
			effect.play(local_player_pos)
