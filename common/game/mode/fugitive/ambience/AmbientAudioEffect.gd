extends AmbientEffect
class_name AmbientAudioEffect

export(Array) var sounds: Array
export(float) var min_radius: float = 10.0
export(float) var max_radius: float = 100.0
export(float) var min_height: float = 0.0
export(float) var max_height: float = 5.0

var audioStreams := []


func _ready():
	for soundPath in sounds:
		audioStreams.push_back(load(soundPath))


func play(localPlayerPos: Vector3):
	.play(localPlayerPos)
	
	var soundPosition := localPlayerPos
	var distance := rand_range(min_radius, max_radius)
	var horizontalDirection := Utils.rand_unit_vec3(Vector3(1.0, 0.0, 1.0))
	horizontalDirection = horizontalDirection * distance
	soundPosition += horizontalDirection
	soundPosition.y = rand_range(min_height, max_height)
	
	
	var oneTimeAudio := OneTimeAudioEffect.new()
	oneTimeAudio.stream = audioStreams[randi() % sounds.size()]
	oneTimeAudio.translation = soundPosition
	add_child(oneTimeAudio)
	
	oneTimeAudio.play()
