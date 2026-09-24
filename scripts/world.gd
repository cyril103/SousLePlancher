extends RefCounted
## Assets créés dans Blender et importés au format glTF.

static func model(root: Node3D, name: String, pos: Vector3) -> Node3D:
	var scene := load("res://assets/models/%s.glb" % name) as PackedScene
	var node := scene.instantiate() as Node3D
	root.add_child(node)
	node.position = pos
	preload("res://scripts/atmosphere.gd").age_materials(node)
	return node

static func caption(parent: Node3D, text: String, pos: Vector3, color: Color = Color("f6dfb8")) -> Label3D:
	var label := Label3D.new()
	label.text = text
	label.font_size = 48
	label.pixel_size = 0.012
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = color
	label.outline_size = 5
	parent.add_child(label)
	label.position = pos
	return label

static func decorate(root: Node3D) -> void:
	model(root, "floor", Vector3.ZERO)
	var atmosphere := preload("res://scripts/atmosphere.gd").new()
	root.add_child(atmosphere)

static func building(root: Node3D, pos: Vector3, kind: String) -> Node3D:
	var node := model(root, "workshop" if kind == "workshop" else "shelter", pos)
	var building_label := caption(node, "Refuge" if kind == "heart" else ("Abri" if kind == "shelter" else "Atelier"), Vector3(0, 1.9, 0))
	building_label.pixel_size = 0.0055
	var atmosphere := root.get_node_or_null("Atmosphere")
	if atmosphere != null:
		atmosphere.add_torch(pos + Vector3(1.05, 0, 0.65))
	return node

static func worker(root: Node3D, pos: Vector3, _index: int) -> Node3D:
	var resident := ResidentAnimator.new()
	root.add_child(resident)
	resident.position = pos + Vector3(0, WorkerDelivery.GROUND_Y, 0)
	return resident

