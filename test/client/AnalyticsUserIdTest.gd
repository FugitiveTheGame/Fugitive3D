extends GdUnitTestSuite

# Analytics identifies an install by an id the game generates and stores, never
# by the device's own. OS.get_unique_id() is Settings.Secure.ANDROID_ID on
# Android, which the app stores count as a device identifier and require to be
# declared in their privacy forms.


func after_test() -> void:
	GameAnalytics.user_id = ''


func test_default_data_carries_an_analytics_id() -> void:
	var id: String = UserData.get_default_data().analytics_id
	assert_str(id).is_not_empty()
	assert_str(id).is_not_equal(OS.get_unique_id())


func test_each_install_gets_its_own_id() -> void:
	assert_str(UserData.get_default_data().analytics_id).is_not_equal(
		UserData.get_default_data().analytics_id)


# An older user data file predates the id, and gains one without losing the
# player's other settings
func test_an_older_file_gains_an_id() -> void:
	var stored: Dictionary = UserData.data.duplicate()
	UserData.data = UserData.get_default_data()
	UserData.data.user_name = "existing player"
	UserData.data.erase('analytics_id')

	UserData.fill_in_missing_settings()

	assert_str(UserData.data.analytics_id).is_not_empty()
	assert_str(UserData.data.user_name).is_equal("existing player")
	UserData.data = stored


func test_events_are_annotated_with_the_games_own_id() -> void:
	GameAnalytics.user_id = "AbC-123"
	assert_str(GameAnalytics._get_user_id()).is_equal("abc-123")


# Left unset, the addon keeps its own behaviour for anyone else using it
func test_an_unset_id_falls_back_to_the_device() -> void:
	GameAnalytics.user_id = ''
	assert_str(GameAnalytics._get_user_id()).is_equal(OS.get_unique_id().to_lower())
