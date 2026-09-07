extends Node
# GameAnalytics <https://gameanalytics.com/> native GDScript REST API implementation
# Cross-platform. Should work in every platform supported by Godot
# Adapted from REST_v2_example.py by Cristiano Reis Monteiro <cristianomonteiro@gmail.com> Abr/2018

const BASE_URL = "https://api.gameanalytics.com"

const MAX_ERROR_MSG_LENGTH = 8192

const UUID = preload("uuid/uuid.gd")

# Platform remaps
const PLATFORMS = {
	'Windows': 'windows',
	'Linux': 'linux',
	'macOS': 'mac_osx',
	'Android': 'android',
	'iOS': 'ios',
	'Web': 'webgl',
}

# Number of events to hold before flushing the event queue
const event_queue_max_events = 16
# A partial queue is flushed once it has been waiting this long
const event_queue_flush_interval = 8.0
# Upper bound on how long the final flush may hold up shutdown
const shutdown_flush_timeout_msec = 2000
# Holds the lifetime session count this install has reported
const state_file_path = "user://gameanalytics_state.json"

# Sessions played since install, including the one about to start
var session_num := 1

var _seconds_since_flush := 0.0


# Game Keys
var game_key = null
var secret_key = null

var build_version = null


func _ready():
	# Events have to keep flowing while the pause menu holds the rest of the tree
	process_mode = Node.PROCESS_MODE_ALWAYS


# global state to track changes when code is running
var state_config = {
	# the amount of seconds the client time is offset by server_time
	# will be set when init call receives server_time
	'client_ts_offset': 0,
	# will be updated when a new session is started
	'session_id': null,
	'session_start': null,
	# set if SDK is disabled or not - default enabled
	'enabled': true,
	# event queue - contains a list of event dictionaries to be JSON encoded
	'event_queue': [],
	# dictionary of currently running progression events
	'ongoing_progression_event_info': {}
}


func _http_free_request(request):
	remove_child(request)
	request.queue_free()


func _http_done(result, response_code, headers, body, http_request, response_handler):
	if response_code == 401:
		log_info("Unauthorized request, make sure you are using a valid game key")
		_http_free_request(http_request)
		return

	var test_json_conv = JSON.new()
	if test_json_conv.parse(body.get_string_from_utf8()) != OK:
		log_info("Invalid JSON recieved from server")
		_http_free_request(http_request)
		return

	self.call(response_handler, response_code, test_json_conv.get_data())
	_http_free_request(http_request)

func _now() -> int:
	return int(Time.get_unix_time_from_system())


func _auth_headers(json_payload) -> PackedStringArray:
	return PackedStringArray([
		"Authorization: " + Marshalls.raw_to_base64(hmac_sha256(json_payload, self.secret_key)),
		"Content-Type: application/json"
	])


func _http_perform_request(endpoint, body, response_handler):
	if !state_config['enabled']:
		log_info("SDK Disabled, not performing any more requests")
		return

	# HTTPRequest needs to be in the tree to work properly
	var http_request = HTTPRequest.new()
	add_child(http_request)

	# TODO: Is request_complete guaranteed to be called? Otherwise, we have a memory leak
	http_request.connect("request_completed", Callable(self, "_http_done").bind(http_request, response_handler))

	var url = BASE_URL + endpoint
	var json_payload = JSON.stringify(body)

	var err = http_request.request(url, _auth_headers(json_payload), HTTPClient.METHOD_POST, json_payload)
	if err != OK:
		log_info("Request failed, with godot error: " + str(err))
		_http_free_request(http_request)


func start_session():
	if state_config['session_id'] != null:
		log_info("Session already started. Not creating a new one")
		return

	session_num = _load_session_num() + 1
	_save_session_num(session_num)

	state_config['session_id'] = UUID.v4()
	state_config['session_start'] = _now()

	log_info("Started session %d with id: %s" % [session_num, state_config['session_id']])
	_init_request()

	# GameAnalytics counts a session only when it sees a user event, so without
	# this every dashboard built on sessions, DAU or playtime stays empty no
	# matter how many design events arrive
	queue_event({'category': 'user'})


func _load_session_num() -> int:
	if not FileAccess.file_exists(state_file_path):
		return 0

	var file = FileAccess.open(state_file_path, FileAccess.READ)
	if file == null:
		return 0

	var parsed = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(parsed) != TYPE_DICTIONARY:
		return 0

	return int(parsed.get('session_num', 0))


func _save_session_num(value: int):
	var file = FileAccess.open(state_file_path, FileAccess.WRITE)
	if file == null:
		log_info("Could not persist the session count to " + state_file_path)
		return

	file.store_string(JSON.stringify({'session_num': value}))
	file.close()


func stop_session():
	if state_config.has('session_start') and state_config['session_start'] is int:
		log_info("Stopped session with id: " + str(state_config['session_id']))
		
		var client_ts = _now()
		queue_event({
			'category': 'session_end',
			'length': client_ts - state_config['session_start']
		})
		_submit_events_blocking()
	
	state_config['session_id'] = null
	state_config['session_start'] = null


# Progression Events
func start_progression(event_id):
	if _progression_event_has_errors('Start', event_id):
		return

	var event_info = _progression_get_event_info(event_id)
	if event_info.running:
		fail_progression(event_id)
		
	event_info.running = true
	state_config.ongoing_progression_event_info[event_id] = event_info
	
	_generic_progression_event('Start', event_id)


func fail_progression(event_id, score = null):
	if _progression_event_has_errors('Fail', event_id):
		return

	var event_info = _progression_get_event_info(event_id)
	if not event_info.running:
		start_progression(event_id)
		
	event_info.running = false
	event_info.counter += 1
	state_config.ongoing_progression_event_info[event_id] = event_info
	_generic_progression_event('Fail', event_id, score)


func complete_progression(event_id, score = null):
	if _progression_event_has_errors('Complete', event_id):
		return

	var event_info = _progression_get_event_info(event_id)
	if not event_info.running:
		start_progression(event_id)
		
	event_info.running = false
	event_info.counter += 1
	state_config.ongoing_progression_event_info[event_id] = event_info
	
	_generic_progression_event('Complete', event_id, score)
	state_config.ongoing_progression_event_info.erase(event_id)


func _generic_progression_event(progression_type, event_id, score = null):
	assert(progression_type in ['Start', 'Fail', 'Complete'])

	var event_info = _progression_get_event_info(event_id)
	var event = {
		'category': 'progression',
		'event_id': progression_type + ':' + event_id,
	}
	
	if progression_type != 'Start':
		event['attempt_num'] = int(event_info.counter)
		if score != null and typeof(score) == TYPE_INT:
			event['score'] = int(score)
		
	queue_event(event)


func _progression_get_event_info(event_id):
	var event_info
	if state_config.ongoing_progression_event_info.has(event_id):
		event_info = state_config.ongoing_progression_event_info[event_id]
	else:
		event_info = {
			'counter': 0,
			'event_id': event_id,
			'running': false
		}
	return event_info
	
func _progression_event_id_already_prefixed(event_id):
	return event_id.find("Start") == 0 or event_id.find("Fail") == 0 or event_id.find("Complete") == 0


func _progression_event_has_errors(progression_type, event_id):
	var has_errors = false
	if _progression_event_id_already_prefixed(event_id):
		push_warning("Tried calling Progression " + progression_type + " but event id already starts with a progression status")
		has_errors = true
	
	if not progression_type in ['Start', 'Fail', 'Complete']:
		push_warning("Unknown progression_type '" + progression_type + "' for progression event '" + event_id + "'")
		has_errors = true

	if event_id.split(':').size() > 3:
		push_warning("Too many dividers ':' in event_id '" + event_id + "'")
		has_errors = true

	return has_errors
# TODO: Send a fail event if we boot the app and have events in ongoing_progression_event_info


# Resource Events
func resource_sink(virtual_currency, item_type, item_id, amount):
	var event = {
		'category': 'resource',
		'event_id': "Sink:" + virtual_currency + ":" + item_type + ":" + item_id,
		'amount': amount
	}
	
	queue_event(event)


func resource_source(virtual_currency, item_type, item_id, amount):
	var event = {
		'category': 'resource',
		'event_id': "Source:" + virtual_currency + ":" + item_type + ":" + item_id,
		'amount': amount
	}
	
	queue_event(event)


# Design Events
func design_event(event_id, value = null):
	var event = {
		'category': 'design',
		'event_id': event_id,
	}
	if value != null and typeof(value) == TYPE_INT:
		event['value'] = int(value)
	
	queue_event(event)


# Error Events
enum ErrorSeverity { DEBUG, INFO, WARNING, ERROR, CRITICAL }
func error_event(severity, message):
	if severity < 0 or severity > ErrorSeverity.size():
		push_warning("Analytics: Severity " + str(severity) + " does not exist")
		return
	var severity_name = ErrorSeverity.keys()[severity].to_lower()
	if message.length() > MAX_ERROR_MSG_LENGTH:
		push_warning("Analytics: Error with severity " + severity_name + " is too long. Size: " + str(message.length()) + " but max allowed is " + str(MAX_ERROR_MSG_LENGTH))
	var event = {
		'category': 'error',
		'severity': severity_name,
		'message': message
	}
	
	queue_event(event)


func _process(delta):
	if state_config['event_queue'].is_empty():
		_seconds_since_flush = 0.0
		return

	_seconds_since_flush += delta
	if state_config['event_queue'].size() >= event_queue_max_events or _seconds_since_flush >= event_queue_flush_interval:
		_submit_events()


## Init Request
func update_client_ts_offset(server_ts):
	# calculate client_ts using offset from server time
	var client_ts = _now()
	var offset = client_ts - server_ts

	# If the difference is too small, ignore it
	state_config['client_ts_offset'] = 0 if abs(offset) < 10 else offset
	log_info('Client TS offset calculated to: ' + str(offset))


func _handle_init_response(response_code, body):
	if response_code < 200 or response_code >= 400:
		return

	state_config['enabled'] = body['enabled']
	state_config['server_ts'] = body['server_ts']
	update_client_ts_offset(state_config['server_ts'])


func _init_request():
	var default_annotations = _get_default_annotations()
	var init_payload = {
		'platform': default_annotations['platform'],
		'os_version': default_annotations['os_version'],
		'sdk_version': default_annotations['sdk_version']
	}

	var endpoint = "/v2/" + self.game_key + "/init"
	_http_perform_request(endpoint, init_payload, "_handle_init_response")


func _handle_submit_events_response(response_code, body):
	if response_code < 200 or response_code >= 400:
		log_info("Submit Error: " + str(body))
		return

	log_info("Events submitted. Response: " + str(body))


func _submit_events():
	_seconds_since_flush = 0.0
	if state_config['event_queue'].is_empty():
		return

	var endpoint = "/v2/" + str(self.game_key) + "/events"
	_http_perform_request(endpoint, state_config['event_queue'], "_handle_submit_events_response")
	# It doesen't really matter if the request succeded, we are not going to send the events again
	state_config['event_queue'] = []


# THAR BE DRAGONS: shutdown tears the tree down before an HTTPRequest node ever
# gets a frame to run in, so the last flush of a session has to be synchronous or
# every event queued since the previous flush is lost.
func _submit_events_blocking():
	_seconds_since_flush = 0.0
	if state_config['event_queue'].is_empty():
		return

	var body = state_config['event_queue']
	state_config['event_queue'] = []

	if !state_config['enabled']:
		log_info("SDK Disabled, not performing any more requests")
		return

	var json_payload = JSON.stringify(body)
	var host = BASE_URL.trim_prefix("https://")

	var client = HTTPClient.new()
	var err = client.connect_to_host(host, 443, TLSOptions.client())
	if err != OK:
		log_info("Final flush could not connect, with godot error: " + str(err))
		return

	var deadline = Time.get_ticks_msec() + shutdown_flush_timeout_msec
	while client.get_status() in [HTTPClient.STATUS_CONNECTING, HTTPClient.STATUS_RESOLVING]:
		client.poll()
		if Time.get_ticks_msec() > deadline:
			log_info("Final flush timed out connecting to " + host)
			return
		OS.delay_msec(5)

	if client.get_status() != HTTPClient.STATUS_CONNECTED:
		log_info("Final flush failed to connect to " + host)
		return

	var endpoint = "/v2/" + str(self.game_key) + "/events"
	err = client.request(HTTPClient.METHOD_POST, endpoint, _auth_headers(json_payload), json_payload)
	if err != OK:
		log_info("Final flush request failed, with godot error: " + str(err))
		return

	while client.get_status() == HTTPClient.STATUS_REQUESTING:
		client.poll()
		if Time.get_ticks_msec() > deadline:
			log_info("Final flush timed out sending " + str(body.size()) + " events")
			return
		OS.delay_msec(5)

	log_info("Final flush of " + str(body.size()) + " events. Response: " + str(client.get_response_code()))
	client.close()


func queue_event(event):
	if typeof(event) != TYPE_DICTIONARY:
		log_info("Submitted an event that's not a dictionary")
		return

	if state_config['session_id'] == null:
		log_info("Dropping '" + str(event.get('event_id', event.get('category', 'unknown'))) + "', no session has been started")
		return

	event = _dict_assign(event, _get_default_annotations())
	state_config['event_queue'].append(event)



static func _dict_assign(target, patch):
	for key in patch:
		target[key] = patch[key]
	return target


# GameAnalytics wants "<platform> <major>[.<minor>[.<patch>]]" and nothing else,
# so keep only the leading numeric run of each component the OS reports
func _get_os_version():
	var platform = PLATFORMS[OS.get_name()]

	var numbers = PackedStringArray()
	for part in OS.get_version().split(".", false):
		var digits = ""
		for index in part.length():
			var character = part[index]
			if character < "0" or character > "9":
				break
			digits += character

		if digits.is_empty():
			break

		numbers.append(digits.left(5))
		if numbers.size() == 3:
			break

	if numbers.is_empty():
		return platform + " 0"

	return platform + " " + ".".join(numbers)


func _get_default_annotations():
	# For some reason GameAnalytics only accepts lower case. Weird but happened to me
	var platform = PLATFORMS[OS.get_name()]
	var os_version = _get_os_version()
	var sdk_version = 'rest api v2'
	var device = OS.get_model_name().to_lower()
	var manufacturer = OS.get_name().to_lower()

	var ts_offset = 0 if not state_config.has('client_ts_offset') else state_config['client_ts_offset']
	var client_ts = _now() - ts_offset

	var default_annotations = {
		'v': 2,                                     # (required: Yes)
		'user_id': OS.get_unique_id().to_lower(),   # (required: Yes)
		#'ios_idfa': idfa,                          # (required: No - required on iOS)
		#'ios_idfv': idfv,                          # (required: No - send if found)
		#'google_aid'                               # (required: No - required on Android)
		#'android_id',                              # (required: No - send if set)
		#'googleplus_id',                           # (required: No - send if set)
		#'facebook_id',                             # (required: No - send if set)
		#'limit_ad_tracking',                       # (required: No - send if true)
		#'logon_gamecenter',                        # (required: No - send if true)
		#'logon_googleplay                          # (required: No - send if true)
		#'gender': 'male',                          # (required: No - send if set)
		#'birth_year                                # (required: No - send if set)
		#'progression                               # (required: No - send if a progression attempt is in progress)
		#'custom_01': 'ninja',                      # (required: No - send if set)
		#'custom_02                                 # (required: No - send if set)
		#'custom_03                                 # (required: No - send if set)
		'client_ts': client_ts,                     # (required: Yes)
		'sdk_version': sdk_version,                 # (required: Yes)
		'os_version': os_version,                   # (required: Yes)
		'manufacturer': manufacturer,               # (required: Yes)
		'device': device,                           # (required: Yes - if not possible set "unknown")
		'platform': platform,                       # (required: Yes)
		'session_id': state_config['session_id'],   # (required: Yes)
		#'build': build_version,                    # (required: No - send if set)
		'session_num': session_num,                 # (required: Yes)
		#'connection_type': 'wifi',                 # (required: No - send if available)
		#'jailbroken                                # (required: No - send if true)
	}
	if build_version:
		default_annotations['build'] = build_version
		
	return default_annotations


func log_info(message):
	print("GameAnalytics: " + str(message))


func hmac_sha256(message, key):
	return Crypto.new().hmac_digest(HashingContext.HASH_SHA256, key.to_utf8_buffer(), message.to_utf8_buffer())


func _exit_tree():
	stop_session()
