extends Control

signal connect_to_server(ip, port)

var is_lan := false
var serverInfo = null


func populate(info):
	serverInfo = info
	
	$NameLabel.text = "%s" % [serverInfo.name]
	$LanIndicator.visible = serverInfo.lan
	$PlayersLabel.text = "%d/%d" % [serverInfo.current_players, serverInfo.max_players]
	
	if serverInfo.is_joinable:
		$ConnectButton.show()
		$NotJoinableLabel.hide()
	else:
		$ConnectButton.hide()
		$NotJoinableLabel.show()



func _on_ConnectButton_pressed():
	emit_signal("connect_to_server", serverInfo.ip, serverInfo.port)
