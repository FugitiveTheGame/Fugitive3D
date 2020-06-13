extends "res://common/lobby/PlayerListItem.gd"


var voice_chat: VoiceChatReceiver  = null


func is_voip_active() -> bool:
	return voice_chat != null and voice_chat.is_playing()
