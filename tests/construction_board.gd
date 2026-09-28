extends "res://tests/live_checkpoint.gd"
const Board = preload("res://scripts/construction_board.gd")
func run() -> void:
	var g := fixture()
	g.prepare_construction_board_demo()
	var rows := Board.entries(g)
	check(rows.size() == 2, "Demo exposes bed and maintenance")
	check("Transport : aucun" in rows[0].detail, "Disabled transport is explained")
	check("pause" in Board.summary(g, rows.size()), "Pause is explicit")
	var before := JSON.stringify(g.Save.capture(g))
	for i in range(10):
		Board.entries(g)
		g.hud._refresh_construction_board()
	check(before == JSON.stringify(g.Save.capture(g)), "Reading and refreshing never mutate saved simulation")
	g.hud._open_construction_entry(1)
	check(g.active_tray == "lantern_service", "Maintenance opens correct commands")
	g._show_tray("construction_board")
	for w in g.workers: w.priorities = {"collect": 0, "transport": 1, "build": 0}
	for i in range(1800):
		step(g)
		if g.construction.supplied(g.sleeping.beds[0]) and g.construction.supplied(g.torches.orders[0]) and g.construction.jobs.is_empty(): break
	rows = Board.entries(g)
	check("Construction : aucun" in rows[0].detail, "Delivered site explains disabled construction")
	check("Bois 4/4" in rows[0].detail and "Fibres 3/3" in rows[0].detail, "Delivered quantities match physical cargo")
	var copy := clone(g, "construction board supplied checkpoint")
	if copy != null:
		check(Board.entries(copy).size() == rows.size(), "Board rebuilds from restored work without new save fields")
		copy.queue_free()
	for w in g.workers: w.priorities.build = 1
	var saw_worker := false
	for i in range(2400):
		step(g)
		for entry in Board.entries(g):
			if "Fabrication" in entry.detail and "H" in entry.detail: saw_worker = true
		if g.sleeping.beds[0].built and g.torches.ready_lanterns() == 2: break
	check(saw_worker, "Assigned builder and live progress visible")
	check(Board.entries(g).is_empty(), "Completed orders disappear")
	g.hud._refresh_construction_board()
	check(g.hud.construction_rows.is_empty(), "UI removes completed cards")
	check(g.stock.wood == 2 and g.stock.fiber == 0, "Board leaves material cost unchanged")
	g.queue_free()
	await process_frame
	g = fixture()
	g.prepare_construction_board_demo()
	# Restore conservation by taking exactly the delivered refill cost from stock.
	g.stock.wood -= 2
	g.torches.orders[0].materials.wood = 2
	check(g.torches.cancel_refill(), "Refill cancellation creates recoverable pile")
	rows = Board.entries(g)
	check(rows.size() == 2 and rows[1].title == "Matériaux récupérables", "Cancellation replaces maintenance with recovery")
	check("Bois 2" in rows[1].detail, "Recovery quantity visible")
	g.hiding = true
	check("Rappel actif" in Board.summary(g, rows.size()), "Recall overrides pause banner")
	g.hiding = false
	for w in g.workers: w.priorities = {"collect": 0, "transport": 1, "build": 1}
	for i in range(2400):
		step(g)
		if g.construction.recovery.is_empty() and g.construction.jobs.is_empty() and g.sleeping.beds[0].built: break
	check(Board.entries(g).is_empty(), "Recovered pile and cancelled tombstone disappear")
	check(g.stock.wood == 6, "Cancelled fuel is fully recovered while bed consumes four wood")
	g.queue_free()
	await process_frame
	g = fixture()
	g.prepare_room_demo()
	rows = Board.entries(g)
	check(rows.size() == 1 and "Sol" in rows[0].title, "Only current room phase displayed")
	g.hud._open_construction_entry(0)
	check(g.active_tray == "rooms" and g.rooms.selected == 0, "Room command selects corresponding room")
	g.discover_east()
	g.plan_east_depot()
	rows = Board.entries(g)
	check(rows[0].title == "Dépôt 1", "Depot numbering matches existing picker")
	g.hud._open_construction_entry(0)
	check(g.active_tray == "depots" and g.hud.depot_picker.selected == 1, "Depot commands select matching depot")
	g.fixed_lighting.plan()
	g.fixed_lighting.site.built = true
	g.fixed_lighting.refill.active = true
	g.fixed_lighting.refill.materials.wood = 2
	for w in g.workers: w.priorities.build = 0
	rows = Board.entries(g)
	var fuel_seen := false
	for entry in rows:
		if entry.title == "Combustible du brasero":
			fuel_seen = true
			check("Réserve prête" in entry.detail and not "Construction : aucun" in entry.detail, "Fuel reserve needs no builder and has no percentage division")
	check(fuel_seen, "Fuel supply site visible")
	g.queue_free()
	await process_frame
	print("CONSTRUCTION_BOARD: %d failure(s)" % failures)
	quit(1 if failures else 0)
