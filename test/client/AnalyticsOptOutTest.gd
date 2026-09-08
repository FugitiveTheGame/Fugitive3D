extends GdUnitTestSuite

# Every analytics call site in the game reaches the GameAnalytics autoload
# directly, so the opt-out has to stop events inside the addon itself
const SETTINGS_DIALOGS := [
	"res://client/main_menu/flat/SettingsDialog.tscn",
	"res://client/main_menu/vr/SettingsDialog.tscn",
]


func before_test() -> void:
	GameAnalytics.collection_enabled = true


func after_test() -> void:
	GameAnalytics.collection_enabled = true


func test_user_data_defaults_to_sharing() -> void:
	assert_bool(UserData.get_default_data().analytics_enabled).is_true()


func test_disabling_drops_queued_events() -> void:
	GameAnalytics.state_config['session_id'] = "test-session"
	GameAnalytics.state_config['session_start'] = 0
	GameAnalytics.queue_event({'category': 'design', 'event_id': 'test_event'})
	assert_array(GameAnalytics.state_config['event_queue']).is_not_empty()

	GameAnalytics.collection_enabled = false

	assert_array(GameAnalytics.state_config['event_queue']).is_empty()
	assert_object(GameAnalytics.state_config['session_id']).is_null()


func test_disabled_events_are_not_queued() -> void:
	GameAnalytics.collection_enabled = false
	GameAnalytics.state_config['session_id'] = "test-session"

	GameAnalytics.design_event("test_event")

	assert_array(GameAnalytics.state_config['event_queue']).is_empty()


# Re-enabling starts a session, which without keys would fire an unauthenticated
# request at the live API
func test_enabling_without_keys_starts_no_session() -> void:
	GameAnalytics.collection_enabled = false
	GameAnalytics.collection_enabled = true

	assert_object(GameAnalytics.state_config['session_id']).is_null()


func test_both_settings_dialogs_expose_the_toggle() -> void:
	var missing: Array[String] = []

	for path in SETTINGS_DIALOGS:
		var dialog := load(path).instantiate() as Window
		auto_free(dialog)

		if dialog.get_node_or_null(dialog.analyticsCheckboxPath) == null:
			missing.append(path.get_file())

	assert_array(missing).override_failure_message(
		"These settings dialogs have no analytics toggle:
  %s" % "
  ".join(missing)).is_empty()
