extends AmbientVisualEffect

var MAX_FIREFLIES := 50
var cur_fireflies := 0
var free_fire_fly_instances := []


func _ready():
	# Fireflies are bad for perf on mobile
	if Utils.renderer_is_gles2():
		MAX_FIREFLIES = 0


func create_new_firefly():
	var firefly := preload("res://common/game/mode/fugitive/ambience/FireFlyInstance.tscn").instance() as FireFlyInstance
	firefly.connect("fire_fly_complete", self, "on_fire_fly_complete")
	
	# Apply random rotation
	var axis := Vector3(randf(), randf(), randf()).normalized()
	var rads = deg2rad(rand_range(0.0, 180.0))
	firefly.transform = firefly.transform.rotated(axis, rads)
	firefly.transform = firefly.transform.orthonormalized()
	
	free_fire_fly_instances.push_back(firefly)
	cur_fireflies += 1;


func _exit_tree():
	for firefly in free_fire_fly_instances:
		firefly.queue_free()
	
	free_fire_fly_instances.clear()


func play(playerPos: Vector3):
	.play(playerPos)
	
	# If we haven't hit our max yet, make a new one
	if free_fire_fly_instances.empty() and cur_fireflies < MAX_FIREFLIES:
		create_new_firefly()
	
	# If we have any fireflies ready in the pool, play an instance of the effect
	if not free_fire_fly_instances.empty():
		var randPos := playerPos
		randPos.x += rand_range(local_bounding_box.position.x, local_bounding_box.end.x)
		randPos.y += rand_range(local_bounding_box.position.y, local_bounding_box.end.y)
		randPos.z += rand_range(local_bounding_box.position.z, local_bounding_box.end.z)
		
		# Pop it off the stack and place it randomly in the world
		var firefly = free_fire_fly_instances.pop_back() as FireFlyInstance
		add_child(firefly)
		firefly.transform.origin = randPos
	#else:
		#print("Out of fire flies")


# Once the effect has finished, remove it from the world
# and add it back to the pool
func on_fire_fly_complete(firefly):
	remove_child(firefly)
	free_fire_fly_instances.push_back(firefly)
