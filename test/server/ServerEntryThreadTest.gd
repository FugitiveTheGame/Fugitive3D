extends GdUnitTestSuite

# Public registration ran on a Thread, carried over from Godot 3. In Godot 4
# that cannot work: the advertiser is a tree node whose HTTPRequest children
# only function inside the tree, so add_child and the IP fetch are
# main-thread-only. Every failure here was silent - the process stayed up and
# systemd reported active while the server never registered, never reached the
# lobby, and so accepted no players.
const SERVER_ENTRY := preload("res://server/ServerEntry.gd")


func _argument_count(obj: Object, method: String) -> int:
	for info in obj.get_method_list():
		if info.name == method:
			return info.args.size()
	return -1


func _property_names(obj: Object) -> Array:
	var names := []
	for info in obj.get_property_list():
		names.append(info.name)
	return names


func test_registration_holds_no_threads() -> void:
	var entry = SERVER_ENTRY.new()
	var properties := _property_names(entry)
	assert_array(properties).not_contains(["registerThread"])
	assert_array(properties).not_contains(["fetchThread"])
	entry.free()


# Both wrappers existed only to absorb Godot 3's Thread userdata argument.
func test_no_leftover_thread_wrappers() -> void:
	var entry = SERVER_ENTRY.new()
	assert_int(_argument_count(entry, "run_register_publicly")).is_equal(-1)
	assert_int(_argument_count(entry, "run_fetch_external_ip")).is_equal(-1)
	entry.free()


# The blocking socketUDP.wait() that justified the thread is replaced by
# polling, so the port check has to be reachable without arguments.
func test_port_check_is_polled() -> void:
	var entry = SERVER_ENTRY.new()
	assert_int(_argument_count(entry, "answer_port_check")).is_equal(0)
	entry.free()


# PacketPeerUDP.listen() is Godot 3. In 4.x it does not exist, and calling a
# missing method returns null, which coerces to 0 and compares equal to OK -
# so the failure reports success and the socket is never bound.
func test_binds_with_the_godot4_api() -> void:
	var socket := PacketPeerUDP.new()
	var names := []
	for info in socket.get_method_list():
		names.append(info.name)

	assert_array(names).contains(["bind"])
	assert_array(names).not_contains(["listen"])
