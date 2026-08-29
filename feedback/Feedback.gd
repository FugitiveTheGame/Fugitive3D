extends Node

const CRASH_FILE_PATH := "user://did_crash"
const LOG_PATH := "user://logs/"

# Mobile clients life cycle isn't as reliable, so disable auto-crash report on mobile
var is_enabled := OS.has_feature("client") and not OS.is_debug_build() and not OS.has_feature("mobile")
var has_crash_to_report := false


func _enter_tree():
	if is_enabled:
		if has_crash():
			has_crash_to_report = true
		else:
			create_crash_gaurd()


func _exit_tree():
	if is_enabled:
		delete_crash_gaurd()


func create_crash_gaurd():
	var crashFile := FileAccess.open(CRASH_FILE_PATH, FileAccess.WRITE)
	crashFile.store_string("did crash?")
	crashFile.close()


func delete_crash_gaurd():
	DirAccess.remove_absolute(CRASH_FILE_PATH)


func has_crash() -> bool:
	return FileAccess.file_exists(CRASH_FILE_PATH)


func crash_now():
	var x = null
	x.crash()


func get_log_file_contents_gzip() -> PackedByteArray:
	var log_contents := get_log_file_contents()
	var uncompressed := log_contents.to_utf8_buffer()
	var gzipped := uncompressed.compress(FileAccess.COMPRESSION_GZIP)
	return gzipped


func get_log_file_contents() -> String:
	var combinedLogContents := ""
	
	var logFileNames = get_log_file_names()
	combinedLogContents += "Log file count: %d\n\n" % logFileNames.size()
	
	for fileName in logFileNames:
		combinedLogContents += "==============================\n"
		combinedLogContents += fileName + "\n"
		combinedLogContents += "==============================\n"
		
		var logFile := FileAccess.open(LOG_PATH + fileName, FileAccess.READ)
		var logContents = logFile.get_as_text()
		logFile.close()
		
		combinedLogContents += logContents + "\n\n"
		
	return combinedLogContents


func get_log_file_names() -> Array:
	var logFiles = []
	var dir = DirAccess.open(LOG_PATH)
	if dir == null:
		return logFiles
	dir.list_dir_begin()

	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name != "log.txt":
			print("Found log: " + file_name)
			logFiles.push_back(file_name)
		file_name = dir.get_next()

	return logFiles
