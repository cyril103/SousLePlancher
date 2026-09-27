extends "res://tests/live_checkpoint.gd"
func wood(g: Node) -> int:
	var count: int = g.depots.total("wood")
	for s in g.construction.sites(): count += s.materials.wood
	for p in g.construction.recovery: count += p.materials.wood
	for w in g.workers:
		if w.kind == "wood": count += w.carrying
	return count
func run() -> void:
	var g := fixture()
	g.prepare_room_demo()
	check(g.rooms.rooms.size() == 1, "Room grid plan accepted")
	if g.rooms.rooms.is_empty():
		quit(1)
		return
	var room: Dictionary = g.rooms.rooms[0]
	var before := wood(g)
	check(not g.rooms.plan(g.HOME), "Occupied room placement refused")
	var other := clone(g, "room plan")
	if other != null: other.queue_free()
	var stages := {}
	for i in range(18000):
		step(g)
		check(wood(g) == before, "Physical room supply preserves wood")
		for p in range(3):
			if room.parts[p].work > 0 and not stages.has(p):
				stages[p] = true
				other = clone(g, "building room stage %d" % p)
				if other != null:
					if p == 1:
						for j in range(10000):
							step(other)
							if other.rooms.rooms[0].parts[2].built: break
						check(other.rooms.rooms[0].parts[2].built and wood(other) == before, "Loaded checkpoint continues room construction")
					other.queue_free()
		if room.parts[2].built: break
	check(room.parts[2].built and stages.size() == 3, "All three stages physically completed")
	if not room.parts[2].built:
		print(g.rooms.summary(0))
		for w in g.workers: print(w.delivery.description())
		quit(1)
		return
	check(g.rooms.set_mode(0, "blocked"), "Empty room can be condemned")
	check(g.travel_path(g.depots.entry(0), room.pos + g.Sleep.ENTRY, 0).is_empty(), "Condemned door physically blocks interior")
	check(not g.rooms.add_bed(0), "Bed cannot be planned behind condemned door")
	check(g.rooms.set_mode(0, "auto"), "Automatic door restores access")
	check(g.rooms.add_bed(0), "Bed blueprint inside finished room")
	check(not g.rooms.set_mode(0, "blocked"), "Cannot isolate bed construction")
	for i in range(5000):
		step(g)
		if g.sleeping.beds[0].built: break
	check(g.sleeping.beds[0].built, "Bed physically supplied and built inside chamber")
	g.sleeping.request_rest(0)
	var door_opened := false
	var slept := false
	for i in range(4000):
		step(g)
		if room.opening > .5: door_opened = true
		if g.workers[0].delivery.state == "sleep":
			slept = true
			other = clone(g, "sleep in constructed chamber")
			if other != null: other.queue_free()
			break
	check(slept and door_opened, "Resident enters through automatic door and sleeps")
	check(not g.rooms.set_mode(0, "blocked"), "Sleeping resident cannot be trapped")
	g.sleeping.interrupt(g.workers[0].delivery)
	for i in range(1600): step(g)
	check(not g.workers[0].delivery.state in ["sleep", "bed_exit"], "Resident can leave room")
	check(wood(g) == before, "Complete construction and rest cycle conserves wood")
	g.queue_free()
	await process_frame
	g = fixture()
	g.prepare_room_demo()
	before = wood(g)
	for i in range(13000):
		step(g)
		if g.rooms.rooms[0].parts[1].work > 2: break
	check(g.rooms.cancel_plan(0), "Partial envelope cancellation")
	check(wood(g) == before, "Cancellation leaves recovery piles")
	other = clone(g, "cancelled chamber")
	if other != null: other.queue_free()
	g.rooms.resume(0)
	for i in range(18000):
		step(g)
		if g.rooms.rooms[0].parts[2].built: break
	check(g.rooms.rooms[0].parts[2].built and wood(g) == before, "Recovery and resumed construction settle")
	g.queue_free()
	await process_frame
	# Older checkpoints retain their original map and no constructed chamber.
	g = fixture()
	var data: Dictionary = g.Save.capture(g)
	data.version = 13
	var runtime: Dictionary = g.Save.Live.unpack(data.runtime.data)
	runtime.erase("rooms")
	data.runtime.data = g.Save.Live.pack(runtime)
	data.runtime.sha256 = JSON.stringify(data.runtime.data).sha256_text()
	check(g.Save.validate(data).is_empty(), "Version 13 migration validates")
	other = fixture()
	check(other.apply_checkpoint(data) and other.rooms.rooms.is_empty(), "Version 13 restores without room plans")
	other.queue_free()
	g.queue_free()
	await process_frame
	print("ROOMS: %d failure(s)" % failures)
	quit(1 if failures else 0)
