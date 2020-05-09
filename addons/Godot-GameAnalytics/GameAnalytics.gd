extends Node
# GameAnalytics <https://gameanalytics.com/> native GDScript REST API implementation
# Cross-platform. Should work in every platform supported by Godot
# Adapted from REST_v2_example.py by Cristiano Reis Monteiro <cristianomonteiro@gmail.com> Abr/2018

var DEVELOPMENT = OS.is_debug_build()

const MAX_ERROR_MSG_LENGTH = 8192

const UUID = preload("uuid/uuid.gd")

# Platform remaps
const PLATFORMS = {
	'Windows': 'windows',
	'X11': 'linux',
	'OSX': 'mac_osx',
	'Android': 'android',
	'iOS': 'ios',
	'HTML5': 'webgl',
}

const ssl_validate_domain = true
# Number of events to hold before flushing the event queue
const event_queue_max_events = 64


# Game Keys
var game_key setget set_game_key, get_game_key
var secret_key setget set_secret_key, get_secret_key

var build_version = null


# sandbox API urls
var base_url = "http://sandbox-api.gameanalytics.com" if DEVELOPMENT else "http://api.gameanalytics.com" 


func set_game_key(new_game_key):
	game_key = new_game_key 


func get_game_key():
	return game_key if not DEVELOPMENT else "5c6bcb5402204249437fb5a7a80a4959"


func set_secret_key(new_secret_key):
	secret_key = new_secret_key


func get_secret_key():
	return secret_key if not DEVELOPMENT else "16813a12f718bc5c620f56944e1abc3ea13ccbac"


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

	var json_result = JSON.parse(body.get_string_from_utf8())
	if json_result.error != OK:
		log_info("Invalid JSON recieved from server")
		_http_free_request(http_request)
		return

	self.call(response_handler, response_code, json_result.result)
	_http_free_request(http_request)

func _http_perform_request(endpoint, body, response_handler):
	if !state_config['enabled']:
		log_info("SDK Disabled, not performing any more requests")
		return

	# HTTPRequest needs to be in the tree to work properly
	var http_request = HTTPRequest.new()
	add_child(http_request)

	# TODO: Is request_complete guaranteed to be called? Otherwise, we have a memory leak
	http_request.connect("request_completed", self, "_http_done", [http_request, response_handler])

	var url = base_url + endpoint
	var json_payload = to_json(body)
	var headers = PoolStringArray([
		"Authorization: " + Marshalls.raw_to_base64(hmac_sha256(json_payload, self.secret_key)),
		"Content-Type: application/json"
	])

	var err = http_request.request(url, headers, ssl_validate_domain, HTTPClient.METHOD_POST, json_payload)
	if err != OK:
		log_info("Request failed, with godot error: " + str(err))
		_http_free_request(http_request)


func start_session():
	if state_config['session_id'] != null:
		log_info("Session already started. Not creating a new one")
		return

	state_config['session_id'] = UUID.v4()
	state_config['session_start'] = OS.get_unix_time_from_datetime(OS.get_datetime())

	log_info("Started session with id: " + str(state_config['session_id']))
	_init_request()


func stop_session():
	log_info("Stopped session with id: " + str(state_config['session_id']))

	var client_ts = OS.get_unix_time_from_datetime(OS.get_datetime())
	queue_event({
		'category': 'session_end',
		'length': client_ts - state_config['session_start']
	})
	_submit_events()
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
	if state_config['event_queue'].size() >= event_queue_max_events:
		_submit_events()


## Init Request
func update_client_ts_offset(server_ts):
	# calculate client_ts using offset from server time
	var client_ts = OS.get_unix_time_from_datetime(OS.get_datetime())
	var offset = client_ts - server_ts

	# If the difference is too small, ignore it
	state_config['client_ts_offset'] = 0 if offset < 10 else offset
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
	var endpoint = "/v2/" + self.game_key + "/events"
	_http_perform_request(endpoint, state_config['event_queue'], "_handle_submit_events_response")
	# It doesen't really matter if the request succeded, we are not going to send the events again
	state_config['event_queue'] = []


func queue_event(event):
	if typeof(event) != TYPE_DICTIONARY:
		log_info("Submitted an event that's not a dictionary")
		return

	event = _dict_assign(event, _get_default_annotations())
	state_config['event_queue'].append(event)



#func get_test_business_event_dict():
#	var event_dict = {
#		'category': 'business',
#		'amount': 999,
#		'currency': 'USD',
#		'event_id': 'Weapon:SwordOfFire',  # item_type:item_id
#		'cart_type': 'MainMenuShop',
#		'transaction_num': 1,  # should be incremented and stored in local db
#		'receipt_info': {'receipt': 'xyz', 'store': 'apple'}  # receipt is base64 encoded receipt
#	}
#	return event_dict
#
#
#func get_test_user_event():
#	var event_dict = {
#		'category': 'user'
#	}
#	return event_dict
#
#
#func get_test_session_end_event(length_in_seconds):
#	var event_dict = {
#		'category': 'session_end',
#		'length': length_in_seconds
#	}
#	return event_dict
#
#
#func get_test_design_event(event_id, value):
#	var event_dict = {
#		'category': 'design',
#		'event_id': event_id,
#		'value': value
#	}
#	return event_dict

static func _dict_assign(target, patch):
	for key in patch:
		target[key] = patch[key]
	return target


func _get_os_version():
	var platform = PLATFORMS[OS.get_name()]
	# Get version number on Android. Need something similar for iOS
	if platform == "android":
		var output = []
		# TODO: Why is this not used?
		var _pid = OS.execute("getprop", ["ro.build.version.release"], true, output)
		# Trimming new line char at the end
		output[0] = output[0].substr(0, output[0].length() - 1)
		return platform + " " + output[0]
	else:
		return platform + ' '


func _get_default_annotations():
	# For some reason GameAnalytics only accepts lower case. Weird but happened to me
	var platform = PLATFORMS[OS.get_name()]
	var os_version = _get_os_version()
	var sdk_version = 'rest api v2'
	var device = OS.get_model_name().to_lower()
	var manufacturer = OS.get_name().to_lower()
	var engine_version = Engine.get_version_info()['string']

	var ts_offset = 0 if not state_config.has('client_ts_offset') else state_config['client_ts_offset']
	var client_ts = OS.get_unix_time_from_datetime(OS.get_datetime()) - ts_offset

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
		'session_num': 1,                           # (required: Yes)
		#'connection_type': 'wifi',                 # (required: No - send if available)
		#'jailbroken                                # (required: No - send if true)
		#'engine_version': engine_version           # (required: No - send if set by an engine)
	}
	if build_version:
		default_annotations['build'] = build_version
		
	return default_annotations


func log_info(message):
	print("GameAnalytics: " + str(message))


func pool_byte_array_from_hex(hex):
	var out = PoolByteArray()

	for idx in range(0, hex.length(), 2):
		var hex_int = ("0x" + hex.substr(idx, 2)).hex_to_int()
		out.append(hex_int)

	return out


# TODO: This sucks, but its what we have right now
# Returns the hex encoded sha256 hash of buffer
func sha256(buffer):
	var path = "user://__ga__sha256_temp"
	var file = File.new()
	file.open(path, File.WRITE)
	file.store_buffer(buffer)
	file.close()
	var sha_hash = file.get_sha256(path)

	Directory.new().remove(path)

	return sha_hash


func hmac_sha256(message, key):
	# Hash key if length > 64
	if key.length() <= 64:
		key = key.to_utf8()
	else:
		key = key.sha256_buffer()

	# Right zero padding if key length < 64
	while key.size() < 64:
		key.append(0)

	var inner_key = PoolByteArray()
	var outer_key = PoolByteArray()

	for idx in range(0, 64):
		outer_key.append(key[idx] ^ 0x5c)
		inner_key.append(key[idx] ^ 0x36)


	var inner_hash = pool_byte_array_from_hex(sha256(inner_key + message.to_utf8()))
	var outer_hash = pool_byte_array_from_hex(sha256(outer_key + inner_hash))

	return outer_hash


func _exit_tree():
	stop_session()
