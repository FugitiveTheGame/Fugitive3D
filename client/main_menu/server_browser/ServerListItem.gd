extends Control

signal connect_to_server(ip, port)

var is_lan := false
var serverInfo = null


func populate(info, lan: bool):
	serverInfo = info
	is_lan = lan
	
	$NameLabel.text = "%s - %s" % [serverInfo.name, serverInfo.ip]
	$LanIndicator.visible = is_lan


func _on_ConnectButton_pressed():
	emit_signal("connect_to_server", serverInfo.ip, serverInfo.port)
