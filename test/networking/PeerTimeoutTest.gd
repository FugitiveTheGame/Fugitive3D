extends GdUnitTestSuite

# A map load blocks the main thread for many seconds. ENet's 5s default
# timeout drops those peers mid-load, which ended rounds the instant they
# started, so both ends must raise the timeout well past a worst-case load.
const WORST_CASE_MAP_LOAD_MS := 30_000


func test_timeout_survives_a_worst_case_map_load() -> void:
	assert_int(ServerNetwork.PEER_TIMEOUT_MIN_MS).is_greater(WORST_CASE_MAP_LOAD_MS)


func test_max_timeout_is_not_below_min() -> void:
	assert_int(ServerNetwork.PEER_TIMEOUT_MAX_MS).is_greater_equal(ServerNetwork.PEER_TIMEOUT_MIN_MS)
