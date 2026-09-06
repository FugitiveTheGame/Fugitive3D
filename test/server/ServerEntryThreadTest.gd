extends GdUnitTestSuite

# Thread.start() invokes the Callable with no arguments. An entry point that
# still declares a parameter dies inside the thread silently: the server
# stays up but never registers, reaches the lobby, or accepts players.
const SERVER_ENTRY := preload("res://server/ServerEntry.gd")


func _argument_count(obj: Object, method: String) -> int:
	for info in obj.get_method_list():
		if info.name == method:
			return info.args.size()
	return -1


func test_thread_entry_point_takes_no_arguments() -> void:
	var entry = SERVER_ENTRY.new()
	assert_int(_argument_count(entry, "register_publicly")).is_equal(0)
	entry.free()


# The arity check above passes either way, because the entry point itself
# always took no arguments; what broke was the call site handing Thread.start
# a userdata-shaped wrapper around it. Guard the wrapper, not just the arity.
func test_no_leftover_userdata_wrapper() -> void:
	var entry = SERVER_ENTRY.new()
	assert_int(_argument_count(entry, "run_register_publicly")).is_equal(-1)
	entry.free()


# This one is started with .bind(advertiser), so it must declare exactly the
# one argument that binding supplies.
func test_bound_thread_entry_point_takes_its_bound_argument() -> void:
	var entry = SERVER_ENTRY.new()
	assert_int(_argument_count(entry, "run_fetch_external_ip")).is_equal(1)
	entry.free()
