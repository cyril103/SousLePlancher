extends RefCounted
## Screen-space policy also works with the orthographic strategy camera.
static func pixel_height(actor: Node3D, height: float) -> float:
	var camera := actor.get_viewport().get_camera_3d()
	if camera == null: return 1000.0
	var center := actor.global_position + Vector3.UP * height * .5
	if camera.is_position_behind(center): return 0.0
	var point := camera.unproject_position(center)
	var pixels := point.distance_to(camera.unproject_position(center + camera.global_basis.y * height))
	if not actor.get_viewport().get_visible_rect().grow(pixels + 64).has_point(point): return 0.0
	return pixels

static func configure_meshes(node: Node) -> void:
	if node is GeometryInstance3D:
		# Imported meshoptimizer LODs, selected using projected screen size.
		node.lod_bias = .35
	for child in node.get_children(): configure_meshes(child)
