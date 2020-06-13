extends "res://common/lobby/PlayerListItem.gd"


var voice_chat: VoiceChatTransceiver = null


func is_voip_active() -> bool:
	return voice_chat != null and voice_chat.is_recording()
