class_name GroundNavigation
extends RefCounted
## Deterministic horizontal routes with clearance for a resident carrying a crate.
const STEP := 0.25
const CLEARANCE := 0.27
const BOUNDS := Rect2(-10.5, -6.5, 21.0, 13.0)
var grid := AStarGrid2D.new()
var obstacles: Array[Rect2] = []
var collision_boxes: Array[Rect2] = []
var revision := 0
var area := BOUNDS

func configure(footprints: Array[Rect2], stands: Array[Rect2] = []) -> void:
	obstacles = footprints.duplicate()
	collision_boxes.clear()
	for box in footprints: collision_boxes.append(box.grow(CLEARANCE))
	# Low loading stands require the close approach authored in the kneeling clip.
	# Keep foot clearance; shoulders and the carried crate pass above their edge.
	for box in stands: collision_boxes.append(box.grow(0.08))
	var first := Vector2i(floori(area.position.x / STEP), floori(area.position.y / STEP))
	var last := Vector2i(ceili(area.end.x / STEP), ceili(area.end.y / STEP))
	grid.region = Rect2i(first, last - first + Vector2i.ONE)
	grid.cell_size = Vector2.ONE * STEP
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	grid.update()
	for y in range(first.y, last.y + 1):
		for x in range(first.x, last.x + 1):
			grid.set_point_solid(Vector2i(x, y), not walkable(Vector3(x * STEP, 0, y * STEP)))
	revision += 1

static func footprint(pos: Vector3, half: Vector2) -> Rect2:
	return Rect2(Vector2(pos.x, pos.z) - half, half * 2)

static func building(pos: Vector3, kind: String) -> Rect2:
	if kind in ["bed", "private_bed"]: return footprint(pos, Vector2(.8, 1.2))
	return footprint(pos, Vector2(0.85, 0.60) if kind == "workshop" else Vector2(0.85, 1.0))

func walkable(pos: Vector3) -> bool:
	var point := Vector2(pos.x, pos.z)
	if not area.grow(-CLEARANCE).has_point(point): return false
	for box in collision_boxes:
		if box.grow(0.001).has_point(point): return false
	return true

func segment_clear(from: Vector3, to: Vector3) -> bool:
	if not walkable(from) or not walkable(to): return false
	var start := Vector2(from.x, from.z)
	var end := Vector2(to.x, to.z)
	for box in collision_boxes:
		var corners := [box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)]
		for i in range(4):
			if Geometry2D.segment_intersects_segment(start, end, corners[i], corners[(i + 1) % 4]) != null: return false
	return true

func connector(point: Vector3) -> Vector2i:
	var cell := Vector2i(roundi(point.x / STEP), roundi(point.z / STEP))
	var best := Vector2i(999, 999)
	var distance := INF
	for y in range(-1, 2):
		for x in range(-1, 2):
			var candidate := cell + Vector2i(x, y)
			if not grid.is_in_boundsv(candidate) or grid.is_point_solid(candidate): continue
			var world := Vector3(candidate.x * STEP, point.y, candidate.y * STEP)
			if point.distance_squared_to(world) < distance and segment_clear(point, world):
				best = candidate
				distance = point.distance_squared_to(world)
	return best

func path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var result := PackedVector3Array()
	if not walkable(from) or not walkable(to): return result
	if segment_clear(from, to): return PackedVector3Array([to])
	var start := connector(from)
	var end := connector(to)
	if start.x == 999 or end.x == 999: return result
	var cells := grid.get_id_path(start, end)
	if cells.is_empty(): return result
	var raw := PackedVector3Array()
	for cell in cells: raw.append(Vector3(cell.x * STEP, to.y, cell.y * STEP))
	raw.append(to)
	# Remove grid zigzags only when the whole shortcut keeps obstacle clearance.
	var anchor := from
	var first := 0
	while first < raw.size():
		var furthest := first
		for i in range(first, raw.size()):
			if segment_clear(anchor, raw[i]): furthest = i
		if not segment_clear(anchor, raw[furthest]): return PackedVector3Array()
		result.append(raw[furthest])
		anchor = raw[furthest]
		first = furthest + 1
	return result

func slots(center: Vector3, count: int, excluded: Array[Vector3] = []) -> Array[Vector3]:
	var result: Array[Vector3] = []
	# Stable front-to-back rows, spaced for distinct waiting/assembly places.
	for row in range(10):
		for col in range(8):
			var offset_x := (float(col / 2) + 0.5) * (1.0 if col % 2 == 0 else -1.0) * 0.72
			var candidate := center + Vector3(offset_x, 0, row * 0.72)
			if not walkable(candidate): continue
			var free := true
			for point in excluded:
				if point.distance_to(candidate) < 0.65: free = false
			if not free: continue
			result.append(candidate)
			if result.size() == count: return result
	return result
