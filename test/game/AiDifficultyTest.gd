extends GdUnitTestSuite

# The three difficulty levels have to differ in the direction the lobby
# promises: harder bots move faster and more directly, see further, remember
# longer and evade better.


func test_labels_name_every_level() -> void:
	assert_str(AiDifficulty.label(AiDifficulty.Level.EASY)).is_equal("Easy")
	assert_str(AiDifficulty.label(AiDifficulty.Level.MEDIUM)).is_equal("Medium")
	assert_str(AiDifficulty.label(AiDifficulty.Level.HARD)).is_equal("Hard")


func test_only_known_levels_are_valid() -> void:
	for level in AiDifficulty.Level.values():
		assert_bool(AiDifficulty.is_valid(level)).is_true()
	assert_bool(AiDifficulty.is_valid(-1)).is_false()
	assert_bool(AiDifficulty.is_valid(AiDifficulty.Level.size())).is_false()
	assert_bool(AiDifficulty.is_valid("Hard")).is_false()
	assert_bool(AiDifficulty.is_valid(null)).is_false()


func test_harder_bots_are_faster_and_more_direct() -> void:
	var easy := AiDifficulty.profile(AiDifficulty.Level.EASY)
	var medium := AiDifficulty.profile(AiDifficulty.Level.MEDIUM)
	var hard := AiDifficulty.profile(AiDifficulty.Level.HARD)

	assert_float(easy.speed_scale).is_less(medium.speed_scale)
	assert_float(medium.speed_scale).is_less(hard.speed_scale)
	# No bot outruns a human
	assert_float(hard.speed_scale).is_less_equal(1.0)

	assert_float(easy.detour_chance).is_greater(medium.detour_chance)
	assert_float(medium.detour_chance).is_greater(hard.detour_chance)
	assert_float(hard.detour_chance).is_equal(0.0)

	assert_float(easy.think_interval).is_greater(hard.think_interval)


func test_harder_bots_notice_more_and_evade_better() -> void:
	var easy := AiDifficulty.profile(AiDifficulty.Level.EASY)
	var hard := AiDifficulty.profile(AiDifficulty.Level.HARD)

	assert_float(easy.see_distance).is_less(hard.see_distance)
	assert_float(easy.caution_distance).is_less(hard.caution_distance)
	assert_float(easy.threat_memory).is_less(hard.threat_memory)
	assert_int(easy.spot_candidates).is_less(hard.spot_candidates)
	assert_bool(easy.keeps_clear_of_cops).is_false()
	assert_bool(hard.keeps_clear_of_cops).is_true()
	assert_bool(easy.sprints_after_headstart).is_false()
	assert_bool(hard.sprints_after_headstart).is_true()
	assert_float(easy.rescue_distance).is_equal(0.0)
	assert_float(hard.rescue_distance).is_greater(0.0)


func test_the_default_is_medium() -> void:
	assert_int(AiDifficulty.DEFAULT).is_equal(AiDifficulty.Level.MEDIUM)
	# An unknown level gets the medium profile
	var fallback := AiDifficulty.profile(99)
	var medium := AiDifficulty.profile(AiDifficulty.Level.MEDIUM)
	assert_float(fallback.speed_scale).is_equal(medium.speed_scale)
	assert_float(fallback.see_distance).is_equal(medium.see_distance)
