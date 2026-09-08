extends GdUnitTestSuite

# The two Android stores disagree about the target SDK, so it cannot be
# unified across the presets. Meta rejects a Quest build above 34; Google Play
# rejects a bundle below 35. Both refusals happen at upload, long after the
# build looks fine, so they are worth catching here.
const META_MAX_TARGET_SDK := 34
const PLAY_MIN_TARGET_SDK := 35

const QUEST_PRESET := "Client VR - Oculus Quest"
const PLAY_PRESET := "Client Flat - Android Google Play"


func _presets() -> ConfigFile:
	var presets := ConfigFile.new()
	assert_int(presets.load("res://export_presets.cfg")).is_equal(OK)
	return presets


# Presets are addressed by name, since their numbering shifts whenever one is
# added or removed in the editor
func _options_for(presets: ConfigFile, preset_name: String) -> String:
	for section in presets.get_sections():
		if section.ends_with(".options"):
			continue
		if presets.get_value(section, "name", "") == preset_name:
			return "%s.options" % section

	fail("No export preset named '%s'" % preset_name)
	return ""


func test_the_quest_build_targets_an_sdk_meta_accepts() -> void:
	var presets := _presets()
	var target: String = presets.get_value(_options_for(presets, QUEST_PRESET), "gradle_build/target_sdk", "")

	assert_str(target).override_failure_message(
		"The Quest preset must pin its target SDK, because the engine default is above what Meta accepts"
	).is_not_empty()
	assert_int(int(target)).is_less_equal(META_MAX_TARGET_SDK)


func test_the_play_bundle_is_left_above_plays_floor() -> void:
	var presets := _presets()
	var target: String = presets.get_value(_options_for(presets, PLAY_PRESET), "gradle_build/target_sdk", "")

	# Empty means the engine default, which is well above Play's floor. A value
	# is only wrong if someone copied the Quest pin across.
	if target.is_empty():
		return

	assert_int(int(target)).override_failure_message(
		"Google Play refuses a bundle below API %d; the Quest cap must not be applied here" % PLAY_MIN_TARGET_SDK
	).is_greater_equal(PLAY_MIN_TARGET_SDK)
