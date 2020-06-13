extends WindowDialog


func _on_FeedbackDialog_about_to_show():
	$Container/DescriptionTextEdit.text = ""
	if Feedback.has_crash_to_report:
		$Container/DescriptionTextEdit.text = "[CRASH DETECTED]\n"
		$Container/SendLogsCheckBox.pressed = true
	else:
		$Container/SendLogsCheckBox.pressed = false
	
	$Container/DescriptionTextEdit.text += "Platform: %s\n\n" % OS.get_name()
	Feedback.has_crash_to_report = false
	
	$Container/SendButton.disabled = false


func _on_SendButton_pressed():
	var userName = "Anonymous"
	if $Container/UserNameEdit.text != null:
		var tempUsername = $Container/UserNameEdit.text.strip_edges()
		if not tempUsername.empty():
			userName = tempUsername
	
	var description := "[EMPTY]"
	if $Container/DescriptionTextEdit.text != null:
		description = $Container/DescriptionTextEdit.text.strip_edges()
	
	var logContents = null
	if $Container/SendLogsCheckBox.pressed:
		logContents = Feedback.get_log_file_contents_gzip()
	
	send_feedback(userName, description, logContents)


func send_feedback(userName: String, description: String, logContents):
	$Container/SendButton.disabled = true
	
	var headers = PoolStringArray()
	headers.push_back("Content-Type: application/x-www-form-urlencoded")
	
	var postBody = "user_name=%s" % userName.percent_encode()
	postBody += "&description=%s" % description.percent_encode()
	
	if logContents != null:
		var base64Logs = Marshalls.raw_to_base64(logContents)
		postBody += "&logs=%s" % base64Logs.percent_encode()

	$HTTPRequest.request("https://fugitivethegame.online/feedback.php", headers, true, HTTPClient.METHOD_POST, postBody)


func _on_HTTPRequest_request_completed(result, response_code, headers, body):
	if response_code >= 200 and response_code < 300:
		print("Feedback sent: " + str(response_code))
		hide()
	else:
		print("Failed to send feedback: " + str(response_code))
		$Container/SendButton.disabled = false
		OS.alert("Failed to send feedback. Please try again.")
