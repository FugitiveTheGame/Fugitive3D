@tool
extends EditorScript

# The GridMap palette thumbnails came through the Godot 3 to 4 conversion as
# noise, and for some items as blank. They are editor-only data, so rendering
# fresh ones and re-saving the library is enough; nothing about the meshes,
# materials or collision shapes is touched.
#
# Run from the script editor with Ctrl+Shift+X, then commit the .meshlib.res
# files it rewrites.

const PREVIEW_SIZE := 64

const LIBRARIES := [
	"res://common/game/tilesets/suburban_neighborhood/suburban_neighborhood_ground.meshlib.res",
	"res://common/game/tilesets/suburban_neighborhood/suburban_neighborhood_features.meshlib.res",
	"res://common/game/tilesets/suburban_neighborhood/suburban_neighborhood_police_features.meshlib.res",
	"res://common/game/tilesets/suburban_neighborhood/suburban_neighborhood_see_through_features.meshlib.res",
	"res://common/game/tilesets/suburban_neighborhood/see_through_features/see_through_features/see_through_features_tiles.meshlib.res",
]


func _run() -> void:
	for pv in LIBRARIES:
		var path: String = pv
		var library := load(path) as MeshLibrary
		if library == null:
			push_error("Could not load %s" % path)
			continue

		var ids := library.get_item_list()
		var meshes: Array[Mesh] = []
		for id in ids:
			meshes.append(library.get_item_mesh(id))

		var previews := EditorInterface.make_mesh_previews(meshes, PREVIEW_SIZE)
		if previews.size() != ids.size():
			push_error("%s: got %d previews for %d items" % [path, previews.size(), ids.size()])
			continue
		for i in ids.size():
			library.set_item_preview(ids[i], previews[i])

		# Keep the compression, otherwise the library balloons back to megabytes.
		var err := ResourceSaver.save(library, path, ResourceSaver.FLAG_COMPRESS)
		if err != OK:
			push_error("%s: save failed (%d)" % [path, err])
		else:
			print("%s: regenerated %d previews" % [path.get_file(), ids.size()])
