extends Node
class_name VoiceChatReceiver

# Opus encodes 20ms per packet, so a burst is a run of packets 20ms apart. A gap
# longer than this ends the burst and resets the decoder.
const STREAM_IDLE_TIMEOUT := 0.5

# Beyond a few frames, concealment sounds worse than the gap it is hiding.
const MAX_CONCEALED_PACKETS := 3

const MIX_RATE := 48000.0
const BUFFER_LENGTH := 0.2

@export var audioPlayerPath: NodePath
@onready var audioPlayer := get_node(audioPlayerPath)

@onready var opus_decoder := $OpusDecoder as OpusDecoderNode

var playback: AudioStreamGeneratorPlayback
var current_sender := 0
var next_sequence := 0
var since_last_packet := 0.0


func _ready():
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = MIX_RATE
	generator.buffer_length = BUFFER_LENGTH
	
	audioPlayer.stream = generator


func _process(delta):
	if not is_playing():
		return
	
	since_last_packet += delta
	if since_last_packet > STREAM_IDLE_TIMEOUT:
		end_stream()


@rpc("any_peer", "call_remote", "unreliable_ordered")
func on_receive_audio(sequence: int, packet: PackedByteArray):
	if packet.is_empty():
		push_warning("Received empty opus packet.")
		return
	
	var sender := multiplayer.get_remote_sender_id()
	
	if not is_playing():
		begin_stream(sender, sequence)
	# Radio and post-game audio from every peer lands on this one node, and one
	# decoder can only follow one stream, so whoever started talking holds it
	elif sender != current_sender:
		return
	
	since_last_packet = 0.0
	
	for i in mini(sequence - next_sequence, MAX_CONCEALED_PACKETS):
		push_frames(opus_decoder.decode_dropped())
	
	push_frames(opus_decoder.decode_frame(packet))
	next_sequence = sequence + 1


func is_playing() -> bool:
	return audioPlayer.playing as bool


func begin_stream(sender: int, sequence: int):
	opus_decoder.reset_stream()
	current_sender = sender
	next_sequence = sequence
	since_last_packet = 0.0
	
	audioPlayer.play()
	playback = audioPlayer.get_stream_playback() as AudioStreamGeneratorPlayback


func end_stream():
	audioPlayer.stop()
	opus_decoder.reset_stream()
	playback = null
	current_sender = 0


func push_frames(frames: PackedVector2Array):
	if playback == null or frames.is_empty():
		return
	
	if playback.can_push_buffer(frames.size()):
		playback.push_buffer(frames)
