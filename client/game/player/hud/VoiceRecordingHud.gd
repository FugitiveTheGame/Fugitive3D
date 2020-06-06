extends Control

export(NodePath) var voiceChatTransceiverPath: NodePath
onready var voiceChatTransceiver := get_node(voiceChatTransceiverPath) as VoiceChatTransceiver

onready var icon := $Icon


func _process(delta):
	icon.visible = voiceChatTransceiver.is_recording()
