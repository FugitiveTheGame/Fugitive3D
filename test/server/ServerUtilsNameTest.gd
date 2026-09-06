extends GdUnitTestSuite

# This was named get_name(), which collides with Resource.get_name() - the
# getter behind resource_name. A class_name resolves to the GDScript resource,
# so the built-in won and every external caller got "" back, while unqualified
# calls from inside ServerUtils reached the static function and worked. The
# split is what made it so hard to see: the LAN broadcast carried the right
# name while public registration sent an empty one and the repository rejected
# it as a name-length violation.

# The repository rejects anything outside this range, measured after trimming.
const REPOSITORY_NAME_MIN := 3
const REPOSITORY_NAME_MAX := 32


func test_default_name_is_not_empty() -> void:
	assert_str(ServerUtils.get_server_name()).is_not_empty()


func test_default_name_satisfies_the_repository_constraint() -> void:
	var server_name := ServerUtils.get_server_name().strip_edges()
	assert_int(server_name.length()).is_greater_equal(REPOSITORY_NAME_MIN)
	assert_int(server_name.length()).is_less_equal(REPOSITORY_NAME_MAX)


# Guard the collision itself: if the accessor is ever renamed back onto a
# built-in, external callers silently get the built-in's value instead.
func test_accessor_does_not_shadow_a_builtin() -> void:
	var probe := RefCounted.new()
	var builtins := []
	for info in probe.get_method_list():
		builtins.append(info.name)

	assert_array(builtins).not_contains(["get_server_name"])
