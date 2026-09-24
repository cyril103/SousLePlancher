extends RefCounted
const NEAR := Vector3(6.65, 2.0295, -4)
const FAR := Vector3(9.35, 2.0295, -4)
const SCOUT_POINT := Vector3(10.2, 2.0295, -3.7)
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

func waiting(id: int, far_side: bool) -> Vector3:
	if far_side: return Vector3(9.4 + (id % 3) * .65, 2.0295, -3.45 - (id / 3) * .65)
	return Vector3(3.45 + (id % 4) * .7, 2.0295, -3.5 - (id / 4) * .7)

func is_edge(from: Vector3, to: Vector3) -> bool:
	return (from.is_equal_approx(NEAR) and to.is_equal_approx(FAR)) or (from.is_equal_approx(FAR) and to.is_equal_approx(NEAR))
