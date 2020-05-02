extends TextureRect

#onready var localPlayer := GameData.currentGame.localPlayer as FugitivePlayer

export(Font) var font: Font


var mapWidth := 115.0
var mapLength := 195.0
var mapSize := Vector2(200, 385)

var mapStart := Vector2(-50.0, 21.0)

onready var roads = GameData.currentMap.roads


func _process(delta):
	if visible:
		update()


func to_map_coord(globalPos: Vector3) -> Vector2:
	var mapScale := (Vector2(globalPos.x, globalPos.z) - mapStart) / mapSize
	mapScale.y += 1.0
	var mapCoord := rect_size * mapScale
	return mapCoord


func _draw():
	for road in roads:
		var fromCoord = null
		for node in road.get_children():
			if node is Position3D:
				var pos = node.global_transform.origin
				if fromCoord == null:
					fromCoord = to_map_coord(pos)
				else:
					var toCoord := to_map_coord(pos)
					draw_line(fromCoord, toCoord, Color.black, 10.0)
					fromCoord = toCoord
	
	for road in roads:
		var namePos := to_map_coord(road.global_transform.origin)
		
		var size = road.get_node("CollisionShape").shape.extents
		var rotation := 0.0
		if size.x < size.z:
			rotation = deg2rad(-90.0)
			namePos -= Vector2(20.0, -20.0)
		else:
			namePos -= Vector2(40.0, 20.0)
			pass
		
		draw_set_transform(namePos, rotation, Vector2(1.0, 1.0))
		draw_string(font, Vector2(), road.street_name)
		draw_set_transform(Vector2(), 0.0, Vector2(1.0, 1.0))
	
	var playerPos := GameData.currentGame.localPlayer.global_transform.origin
	var playerCoord = to_map_coord(playerPos)
	draw_circle(playerCoord, 10.0, Color.red)
