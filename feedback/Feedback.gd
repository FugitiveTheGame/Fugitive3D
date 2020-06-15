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
	var crashFile := File.new()
	crashFile.open(CRASH_FILE_PATH, File.WRITE)
	crashFile.store_string("did crash?")
	crashFile.close()


func delete_crash_gaurd():
	var dir = Directory.new()
	dir.remove(CRASH_FILE_PATH)


func has_crash() -> bool:
	var dir = Directory.new()
	if dir.file_exists(CRASH_FILE_PATH):
		return true
	else:
		return false


func crash_now():
	var x = null
	x.crash()


func get_log_file_contents_gzip() -> PoolByteArray:
	var log_contents := get_log_file_contents()
	var uncompressed := log_contents.to_utf8()
	var gzipped := uncompressed.compress(File.COMPRESSION_GZIP)
	return gzipped


func get_log_file_contents() -> String:
	var combinedLogContents := ""
	
	var logFileNames = get_log_file_names()
	combinedLogContents += "Log file count: %d\n\n" % logFileNames.size()
	
	for fileName in logFileNames:
		combinedLogContents += "==============================\n"
		combinedLogContents += fileName + "\n"
		combinedLogContents += "==============================\n"
		
		var logFile := File.new()
		logFile.open(LOG_PATH + fileName, File.READ)
		var logContents = logFile.get_as_text()
		logFile.close()
		
		combinedLogContents += logContents + "\n\n"
		
	return combinedLogContents


func get_log_file_names() -> Array:
	var logFiles = []
	var dir = Directory.new()
	dir.open(LOG_PATH)
	dir.list_dir_begin()
	
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name != "log.txt":
			print("Found log: " + file_name)
			logFiles.push_back(file_name)
		file_name = dir.get_next()

	return logFiles
