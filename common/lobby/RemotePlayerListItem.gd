extends "res://common/lobby/PlayerListItem.gd"

onready var voice_chat := $VoiceChat as VoiceChatReceiver


func is_voip_active() -> bool:
	return voice_chat.is_playing()
