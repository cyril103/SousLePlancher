class_name DeliveryLedger
extends RefCounted
## Resource transactions: reserved != collected != delivered.
var patches: Array[Dictionary] = []
var jobs: Dictionary = {}
var source_slots: Dictionary = {}
var destination_owner := -1
var destination_queue: Array[int] = []
var next_id := 1

func reserve(owner: int, source: int, capacity: int) -> int:
	if source < 0 or source >= patches.size() or source_slots.has(source): return -1
	for job in jobs.values():
		if job.owner == owner: return -1
	var patch := patches[source]
	var quantity := mini(capacity, int(patch.amount) - int(patch.get("reserved", 0)))
	if quantity <= 0: return -1
	var id := next_id
	next_id += 1
	patch.reserved = int(patch.get("reserved", 0)) + quantity
	jobs[id] = {"owner": owner, "source": source, "quantity": quantity, "kind": patch.kind, "collected": false}
	source_slots[source] = id
	return id

func collect(id: int) -> int:
	if not jobs.has(id) or jobs[id].collected: return 0
	var job: Dictionary = jobs[id]
	var patch := patches[job.source]
	patch.reserved -= job.quantity
	patch.amount -= job.quantity
	job.collected = true
	return job.quantity

func leave_source(id: int) -> void:
	if not jobs.has(id): return
	var source: int = jobs[id].source
	if source_slots.get(source, -1) == id: source_slots.erase(source)

func acquire_destination(id: int) -> bool:
	if not jobs.has(id) or not jobs[id].collected: return false
	if destination_owner == id: return true
	if not destination_queue.has(id): destination_queue.append(id)
	if destination_owner != -1 or destination_queue.front() != id: return false
	destination_queue.pop_front()
	destination_owner = id
	return true

func deliver(id: int, stock: Dictionary) -> int:
	if not jobs.has(id) or not jobs[id].collected or destination_owner != id: return 0
	var job: Dictionary = jobs[id]
	var quantity: int = job.quantity
	stock[job.kind] += quantity
	leave_source(id)
	jobs.erase(id)
	# Keep the physical unloading slot until the actor has finished standing up.
	return quantity

func release_destination(id: int) -> void:
	if destination_owner == id: destination_owner = -1
	destination_queue.erase(id)

func cancel(id: int) -> bool:
	if not jobs.has(id): return true
	var job: Dictionary = jobs[id]
	if job.collected: return false # Caller must bring the existing load home.
	patches[job.source].reserved -= job.quantity
	leave_source(id)
	release_destination(id)
	jobs.erase(id)
	return true
