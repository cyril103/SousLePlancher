extends "res://tests/live_checkpoint.gd"
func click(g: Node, pos: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = pos
	g._unhandled_input(event)
func run() -> void:
	var g := fixture()
	g.prepare_harvest_markers_demo()
	await process_frame
	check("Réserve couverte" in g.patches[2].label.text, "Wood label reflects covered target")
	check("objectif 0" in g.patches[7].label.text, "Water label explains zero target")
	check("Sans ordre" in g.patches[0].label.text, "Unselected food has no designation")
	check("Récolte désignée" in g.patches[4].label.text, "Fiber label reflects designation")
	var before: String = JSON.stringify(g.Save.capture(g).runtime)
	for angle in [.32, -.8, 1.4]:
		g.yaw = angle
		for distance in [17.0, 28.0, 45.0]:
			g.zoom = distance
			g._update_camera()
			g._refresh_ui()
			for id in g.local_harvest.PATCHES:
				var rect: Rect2 = g.local_harvest.marker_rect(id)
				check(rect.has_area(), "Discovered visible label has a hit area")
				click(g, rect.get_center())
				check(g.selected == id and g.active_tray == "harvest_source", "Label selects correct source across camera changes")
	check(before == JSON.stringify(g.Save.capture(g).runtime), "Label selection changes no tasks or reservations")
	g.patches[4].node.hide()
	check(not g.local_harvest.marker_rect(4).has_area(), "Hidden label cannot receive clicks")
	g.patches[4].node.show()
	g.patches[4].discovered = false
	check(not g.local_harvest.marker_rect(4).has_area(), "Undiscovered source cannot receive label clicks")
	g.patches[4].discovered = true
	g.hiding = true
	g._refresh_ui()
	check("Rappel" in g.patches[4].label.text, "Recall appears without removing order")
	g.hiding = false
	g.yaw = .32
	g.zoom = 28
	g._update_camera()
	for i in range(900):
		step(g)
		if not g.delivery_ledger.jobs.is_empty(): break
	g._refresh_ui()
	check("porteur(s)" in g.patches[4].label.text, "Actual reservation appears on label")
	g.local_harvest.set_active(4, false)
	g._refresh_ui()
	check("Sans ordre" in g.patches[4].label.text and "porteur(s)" in g.patches[4].label.text, "Suspended source still shows committed work")
	var copy := clone(g, "harvest marker mission")
	if copy != null:
		check(copy.patches[4].label.text.trim_prefix("▸ ") == g.patches[4].label.text.trim_prefix("▸ "), "Label reconstructed from saved state")
		copy.queue_free()
	g.patches[0].amount = 0
	g._refresh_ui()
	check("Épuisé" in g.patches[0].label.text, "Exhausted source remains identifiable")
	g._choose_build("bed")
	click(g, g.local_harvest.marker_rect(2).get_center())
	check(g.active_tray != "harvest_source", "Label click does not intercept building placement")
	g._cancel_build()
	g.queue_free()
	await process_frame
	print("HARVEST_MARKERS: %d failure(s)" % failures)
	quit(1 if failures else 0)
