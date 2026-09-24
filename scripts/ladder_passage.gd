extends RefCounted
## A single shared passage. Ownership includes approach and clearing the landing.
const HEIGHT := 2.04
const BASE := Vector3(6, 0, -3)
const LOWER := BASE + Vector3(0, -0.0105, 0.36)
const UPPER := BASE + Vector3(0, 2.0295, -0.3807)
var owner := -1
var queue: Array[int] = []

func request(id: int) -> bool:
	if owner == id: return true
	if not queue.has(id): queue.append(id)
	if owner < 0 and queue[0] == id:
		queue.pop_front()
		owner = id
		return true
	return false

func release(id: int) -> void:
	if owner == id: owner = -1
	queue.erase(id)

func waiting(id: int, upper: bool) -> Vector3:
	# Two sheltered rows, outside the entry/exit corridor; stable per resident.
	if upper: return Vector3(3.45 + (id % 4) * 0.7, 2.0295, -3.5 - (id / 4) * 0.7)
	return Vector3(5.4 + (id % 4) * 0.7, -0.0105, -1.5 + (id / 4) * 0.7)

func sample(actor: Node3D, time: float, upward: bool) -> Dictionary:
	actor.rotation.y = PI
	var clip: String
	var frame: float
	var offset: Vector3
	if upward:
		if time < 1.2:
			offset = Vector3(0, -.0105 * (1 - smoothstep(0, 1.2, time)), .36)
			clip = "climb_enter"; frame = time
		elif time < 6.0:
			var height := (time - 1.2) * .31875
			offset = Vector3(0, height, .36 - .19 * height)
			clip = "climb"; frame = fposmod(time - 1.2, 1.6)
		else:
			offset = Vector3(0, 1.53 - .0105 * smoothstep(6, 7.4, time), .0693)
			clip = "climb_exit"; frame = minf(time - 6, 1.4)
	else:
		if time < 1.4:
			offset = Vector3(0, 1.53 - .0105 * (1 - smoothstep(0, 1.4, time)), .0693)
			clip = "descend_enter"; frame = time
		elif time < 6.8:
			var height := 1.53 - (time - 1.4) * (.51 / 1.8)
			offset = Vector3(0, height, .36 - .19 * height)
			clip = "climb_down"; frame = fposmod(time - 1.4, 1.8)
		else:
			offset = Vector3(0, -.0105 * smoothstep(6.8, 8, time), .36)
			clip = "descend_exit"; frame = minf(time - 6.8, 1.2)
	actor.position = BASE + offset
	return {"clip": clip, "time": frame}
