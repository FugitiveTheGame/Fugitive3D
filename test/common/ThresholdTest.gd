extends GdUnitTestSuite


func test_first_check_exceeds() -> void:
	var threshold := Threshold.new(50)
	assert_bool(threshold.is_exceeded()).is_true()


func test_within_threshold_does_not_exceed() -> void:
	var threshold := Threshold.new(60_000)
	threshold.is_exceeded()
	assert_bool(threshold.is_exceeded()).is_false()


func test_reset_allows_exceeding_again() -> void:
	var threshold := Threshold.new(60_000)
	threshold.is_exceeded()
	threshold.reset()
	assert_bool(threshold.is_exceeded()).is_true()


func test_stopped_threshold_never_exceeds() -> void:
	var threshold := Threshold.new(50, false)
	assert_bool(threshold.is_exceeded()).is_false()
