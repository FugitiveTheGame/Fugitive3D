extends GdUnitTestSuite

# The headset only honours rates it advertises, so the setting is a request that
# VrCompat has to snap onto the supported list
const DIALOG := "res://client/main_menu/vr/SettingsDialog.tscn"


func test_default_is_the_universally_supported_rate() -> void:
	assert_int(UserData.get_default_data().vr_refresh_rate).is_equal(72)


func test_dialog_offers_72_and_90() -> void:
	var dialog := load(DIALOG).instantiate() as Window
	auto_free(dialog)

	var options := dialog.get_node_or_null(dialog.refreshRateOptionsPath) as OptionButton
	assert_object(options).override_failure_message(
		"The VR settings dialog has no refresh rate control").is_not_null()

	var offered: Array[String] = []
	for index in range(options.item_count):
		offered.append(options.get_item_text(index))
	assert_array(offered).contains_exactly(["72 Hz", "90 Hz"])


func test_dialog_items_line_up_with_the_saved_values() -> void:
	var dialog := load(DIALOG).instantiate() as Window
	auto_free(dialog)

	var options := dialog.get_node_or_null(dialog.refreshRateOptionsPath) as OptionButton
	for index in range(options.item_count):
		assert_str(options.get_item_text(index)).starts_with(
			str(dialog.REFRESH_RATES[index]))


func test_unsupported_rate_is_not_requested() -> void:
	# No headset in a headless test run, so nothing is advertised
	assert_array(vr.get_supported_refresh_rates()).is_empty()
	vr.set_display_refresh_rate(90.0)
