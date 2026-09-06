extends GdUnitTestSuite


func after_test() -> void:
	ClientNetwork.reset_network()


func test_not_hosting_before_host_game() -> void:
	assert_bool(ServerNetwork.is_hosting()).is_false()


func test_hosting_after_host_game() -> void:
	assert_bool(ServerNetwork.host_game(31991)).is_true()
	assert_bool(ServerNetwork.is_hosting()).is_true()


func test_not_hosting_after_reset_network() -> void:
	ServerNetwork.host_game(31992)
	ClientNetwork.reset_network()
	assert_bool(ServerNetwork.is_hosting()).is_false()
