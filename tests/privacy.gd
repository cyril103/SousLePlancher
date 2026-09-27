extends "res://tests/live_checkpoint.gd"
func run() -> void:
	var g := fixture()
	g.prepare_privacy_demo()
	check(g.Navigation.BOUNDS.get_area() == 4 * 21 * 13, "Playable rectangle has four times its old area")
	check(g.rooms.rooms.size() == 4 and g.sleeping.beds.size() == 4, "Four separate rooms and beds fit expanded ground")
	if g.rooms.rooms.size() != 4 or g.sleeping.beds.size() != 4:
		print("Rooms ", g.rooms.rooms.size(), " beds ", g.sleeping.beds.size())
		quit(1)
		return
	check(not g.travel_path(g.depots.entry(0), Vector3(-19, -.0105, 11), 0).is_empty(), "Extended west/south area is reachable")
	check(g.travel_path(g.depots.entry(0), g.fissure.FAR, 0).is_empty(), "Expansion cannot bypass dedicated alcove passage")
	for i in range(4):
		check(g.rooms.room_at(g.sleeping.beds[i].pos) == i, "Bed detected geometrically inside its completed room")
		check(g.rooms.owner_name(g.rooms.rooms[i]) == "H%d" % (i + 1), "Distinct personal owners")
	var other := clone(g, "four expanded rooms")
	if other != null: other.queue_free()
	var all_asleep := false
	for i in range(2400):
		step(g)
		var sleeping := 0
		for w in g.workers:
			if w.delivery.state == "sleep": sleeping += 1
		if sleeping == 4:
			all_asleep = true
			break
	check(all_asleep, "All four autonomously reach their assigned beds")
	for i in range(12): step(g)
	check(g.workers[0].privacy == 95.0, "Closed personal room grants measured privacy")
	check(not g.rooms.assign_owner(0, -1), "Ownership cannot change during occupation")
	g.rooms.set_mode(0, "open")
	step(g)
	check(g.workers[0].privacy == 35.0, "Open door immediately reduces sleeping privacy")
	g.rooms.set_mode(0, "auto")
	for i in range(12): step(g)
	check(g.workers[0].privacy == 95.0, "Privacy recovers after door closes")
	var saved_position: Vector3 = g.workers[1].node.position
	g.workers[1].node.position = g.rooms.rooms[0].pos + Vector3(.9, -.0105, .2)
	var quality: Dictionary = g.rooms.rest_quality(g.sleeping.beds[0], 0)
	check(quality.privacy == 25.0, "Another resident in room reduces privacy")
	g.workers[1].node.position = saved_position
	other = clone(g, "sleep and privacy in expanded rooms")
	if other != null:
		check(other.workers[0].privacy == g.workers[0].privacy, "Privacy survives save/load")
		for i in range(1600): step(other)
		check(other.workers[0].delivery.state != "sleep", "Loaded sleepers finish rest and can leave")
		other.queue_free()
	for i in range(1800): step(g)
	check(g.rooms.assign_owner(0, -1), "Free room can become collective")
	check(g.rooms.rest_quality(g.sleeping.beds[0], 0).privacy == 60.0, "Collective room has distinct privacy")
	check(g.rooms.assign_owner(0, 1), "Room can be reassigned after rest")
	check(g.sleeping.beds[1].owner == -1 and g.sleeping.beds[0].owner == 1, "Ownership stays synchronized with beds without duplicates")
	other = clone(g, "changed room ownership")
	if other != null: other.queue_free()
	# Extended coordinates require the new version, old coordinates still migrate.
	var data: Dictionary = g.Save.capture(g)
	data.version = 14
	check(not g.Save.validate(data).is_empty(), "Expanded building coordinates are versioned")
	g.queue_free()
	await process_frame
	g = fixture()
	g.prepare_room_demo()
	data = g.Save.capture(g)
	data.version = 14
	check(g.Save.validate(data).is_empty(), "Authentic old-size room checkpoint still validates")
	other = fixture()
	check(other.apply_checkpoint(data), "Version 14 room restores on expanded map")
	other.queue_free()
	g.queue_free()
	await process_frame
	# Physical supply and recovery at the new southern/western map limits.
	g = fixture()
	g.start_panel.hide()
	g.stock.wood = 20
	g.stock.fiber = 12
	check(g.rooms.plan(Vector3(-17, 0, 8)), "Far room blueprint within expanded ground")
	for i in range(22000):
		step(g)
		if g.rooms.rooms[0].parts[1].work > 2: break
	check(g.rooms.rooms[0].parts[1].work > 2, "Materials physically carried to far room")
	check(g.rooms.cancel_plan(0), "Far room construction can be cancelled")
	other = clone(g, "recovery piles on enlarged southern edge")
	if other != null: other.queue_free()
	g.rooms.resume(0)
	for i in range(22000):
		step(g)
		if g.rooms.rooms[0].parts[2].built: break
	check(g.rooms.rooms[0].parts[2].built, "Far room completes after recovery and resupply")
	g.queue_free()
	await process_frame
	print("PRIVACY: %d failure(s)" % failures)
	quit(1 if failures else 0)
