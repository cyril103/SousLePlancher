extends Node3D
## Approved Blender kit; explicit door passage through the exterior obstacle.
const CAPACITY := 6
const FOOTPRINT := Rect2(-1.08, -2.18, 2.16, 3.16)
const OUTSIDE := Vector3(0, -0.0105, 1.5)
const INSIDE := Vector3(0, -0.0105, .35)
var passage_owner := -1
var queue: Array[int] = []
var door: Node3D
var opening := 0.0
var front: Node3D
var side: Node3D
var cutaway := false

func _ready() -> void:
	var floor_model := asset("reference_01/floor_module_2x2", Vector3(0, 0, -.6))
	floor_model.scale.z = 1.5
	asset("refuge_02/wall_window_2m", Vector3(0, 0, -2.1))
	for x in [-1.0, 1.0]:
		var wall := asset("refuge_02/wall_solid_2m", Vector3(x, 0, -.6))
		wall.rotation.y = PI / 2
		wall.scale.x = 1.5
		if x > 0: side = wall
	front = asset("refuge_02/wall_doorway_2m", Vector3(0, 0, .9))
	door = asset("refuge_02/door_leaf_1m", Vector3(-.505, 0, .975))
	var light := OmniLight3D.new()
	light.position = Vector3(0, 1.6, -.9)
	light.light_color = Color("ffc17c")
	light.light_energy = .45
	light.omni_range = 2.4
	add_child(light)

func asset(path: String, location: Vector3) -> Node3D:
	var node := (load("res://assets/models/" + path + ".glb") as PackedScene).instantiate() as Node3D
	add_child(node)
	node.position = location
	return node

func slot(id: int) -> Vector3:
	# A central aisle stays clear; rear places fill first.
	return position + Vector3(.58 if id % 2 == 0 else -.58, -.0105, -1.72 + (id / 2) * .64)

func request(id: int) -> bool:
	if passage_owner == id: return true
	if not queue.has(id): queue.append(id)
	if passage_owner < 0 and queue[0] == id:
		queue.pop_front()
		passage_owner = id
		return true
	return false

func release(id: int) -> void:
	queue.erase(id)
	if passage_owner == id: passage_owner = -1

func update(dt: float) -> void:
	opening = move_toward(opening, 1.0 if passage_owner >= 0 else 0.0, dt / .55)
	door.rotation.y = deg_to_rad(100) * smoothstep(0, 1, opening)

func set_cutaway(value: bool) -> void:
	cutaway = value
	# Keep the door and its frame visible to make the crossing readable.
	side.visible = not cutaway
