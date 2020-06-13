extends Control

const MIN_NAME_LENGTH := 3

export(NodePath) var playerNamePath: NodePath
onready var playerNameInput := get_node(playerNamePath) as LineEdit

export(NodePath) var serverIpPath: NodePath
onready var serverIpInput := get_node(serverIpPath) as LineEdit

export(NodePath) var serverPortPath: NodePath
onready var serverPortInput := get_node(serverPortPath) as LineEdit

export(NodePath) var versionLabelPath: NodePath
onready var versionLabel := get_node(versionLabelPath) as Label

export (NodePath) var joiningDialogPath: NodePath
onready var joiningDialog := get_node(joiningDialogPath) as WindowDialog

export (NodePath) var joinFailedDialogPath: NodePath
onready var joinFailedDialog := get_node(joinFailedDialogPath) as AcceptDialog

export (NodePath) var badInputDialogPath: NodePath
onready var badInputDialog := get_node(badInputDialogPath) as AcceptDialog

export (NodePath) var lostConnectionDialogPath: NodePath
onready var lostConnectionDialog := get_node(lostConnectionDialogPath) as AcceptDialog

export (NodePath) var helpDialogPath: NodePath
onready var helpDialog := get_node(helpDialogPath) as WindowDialog

export (NodePath) var menuMusicButtonPath: NodePath
onready var menuMusicButton := get_node(menuMusicButtonPath) as CheckButton

export (NodePath) var menuMusicPlayerPath: NodePath
onready var menuMusicPlayer := get_node(menuMusicPlayerPath) as AudioStreamPlayer

export (NodePath) var feedbackDialogPath: NodePath
onready var feedbackDialog := get_node(feedbackDialogPath) as WindowDialog

export (NodePath) var crashDetectedDialogPath: NodePath
onready var crashDetectedDialog := get_node(crashDetectedDialogPath) as AcceptDialog


func _enter_tree():
	get_tree().connect("connected_to_server", self, "on_connected_to_server")
	get_tree().connect("connection_failed", self, "on_connection_failed")


func _exit_tree():
	get_tree().disconnect("connected_to_server", self, "on_connected_to_server")
	get_tree().disconnect("connection_failed", self, "on_connection_failed")
	
	joiningDialog.hide()
	
	UserData.data.user_name = playerNameInput.text
	UserData.data.last_ip = serverIpInput.text
	UserData.data.last_port = serverPortInput.text
	UserData.save_data()


func _ready():
	versionLabel.text = "v%d" % UserData.GAME_VERSION
	
	playerNameInput.text = UserData.data.user_name
	serverIpInput.text = UserData.data.last_ip
	serverPortInput.text = str(UserData.data.last_port)
	
	menuMusicButton.pressed = UserData.data.menu_music
	update_menu_music()
	
	if ClientNetwork.has_disconnect_reason():
		lostConnectionDialog.dialog_text = ClientNetwork.consume_disconnect_reason()
		lostConnectionDialog.popup_centered()
	
	if Feedback.has_crash_to_report:
		print("Has crash to report")
		feedbackDialog.popup_centered()
		crashDetectedDialog.call_deferred("popup_centered")


func _on_ConnectButton_pressed():
	var ip := (serverIpInput.text as String).strip_edges()
	
	var portStr := serverPortInput.text as String
	var port := int(portStr)
	
	if validate_manual_connect(ip, port):
		GameAnalytics.design_event("manual_connect_request")
		on_connect_request(ip, port)
	else:
		GameAnalytics.error_event(GameAnalytics.ErrorSeverity.WARNING, "Manual connect with bad data")
		badInputDialog.popup_centered()


func validate_manual_connect(ip: String, port: int) -> bool:
	var valid := true
	
	if ip.empty():
		valid = false
	
	if port <= 0 or port > 65535:
		valid = false
	
	return valid


func connect_to_server(playerName: String, serverIp: String, serverPort: int):
	if playerName.strip_edges().length() < MIN_NAME_LENGTH:
		$UserNameErrorDialog.popup_centered()
		GameAnalytics.error_event(GameAnalytics.ErrorSeverity.INFO, "Bad user name length")
		return
	
	vr.log_info("connect_to_server")
	if ClientNetwork.join_game(serverIp, serverPort, playerName.strip_edges()):
		joiningDialog.popup_centered()
	else:
		GameAnalytics.error_event(GameAnalytics.ErrorSeverity.WARNING, "Failed to start connection")
		joinFailedDialog.popup_centered()


func on_connected_to_server():
	vr.log_info("on_connected_to_server")
	GameAnalytics.design_event("joining_lobby")
	go_to_lobby()


func on_connection_failed():
	GameAnalytics.error_event(GameAnalytics.ErrorSeverity.WARNING, "Failed to connect to server")
	joiningDialog.hide()
	joinFailedDialog.popup_centered()


func go_to_lobby():
	print("go_to_lobby() MUST BE OVERRIDEN")


func _on_ServerBrowser_connect_to_server(ip: String, port: int):
	GameAnalytics.design_event("server_browser_connect_request")
	on_connect_request(ip, port)


func on_connect_request(ip: String, port: int):
	var playerName := playerNameInput.text as String
	connect_to_server(playerName, ip, port)


func _on_ExitButton_pressed():
	print("Closing game")
	GameAnalytics.design_event("explicit_exit_game")
	get_tree().quit()


func _on_CancelButton_pressed():
	ClientNetwork.reset_network()
	GameAnalytics.design_event("cancel_join_request")
	joiningDialog.hide()


func _on_HelpButton_pressed():
	helpDialog.popup_centered()


func _on_MenuMusicButton_toggled(button_pressed):
	UserData.data.menu_music = button_pressed
	UserData.save_data()
	update_menu_music()


func update_menu_music():
	menuMusicPlayer.playing = UserData.data.menu_music


func _on_FeedbackButton_pressed():
	if not feedbackDialog.visible:
		feedbackDialog.popup_centered()
