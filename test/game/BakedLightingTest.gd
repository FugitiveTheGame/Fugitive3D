extends GdUnitTestSuite

# Once a surface carries a lightmap, Godot stops applying the Environment's
# ambient to it, on the assumption the bake already contains it. But the
# lightmapper samples the sky, not ambient_light_color, and this map's sky is a
# dim night panorama. Left on ENVIRONMENT_MODE_SCENE the bake therefore arrives
# with almost no ambient, and baking makes the map darker than it was unbaked.
const BASE_MAP := "res://common/game/base_maps/FugitiveSuburbanMap.tscn"


func test_the_bake_supplies_its_own_ambient_light() -> void:
	var root: Node = load(BASE_MAP).instantiate()
	auto_free(root)

	var lightmap := _find_lightmap(root)
	assert_object(lightmap).override_failure_message(
		"No LightmapGI found in %s" % BASE_MAP).is_not_null()

	assert_int(lightmap.environment_mode).override_failure_message(
		"environment_mode=%d leaves the bake taking its ambient from the night sky"
		% lightmap.environment_mode).is_equal(LightmapGI.ENVIRONMENT_MODE_CUSTOM_COLOR)
	assert_float(lightmap.environment_custom_energy).is_greater(0.0)


func _find_lightmap(node: Node) -> LightmapGI:
	if node is LightmapGI:
		return node
	for child in node.get_children():
		var found := _find_lightmap(child)
		if found != null:
			return found
	return null
