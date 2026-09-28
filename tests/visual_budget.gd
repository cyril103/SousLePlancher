extends "res://tests/live_checkpoint.gd"

func run() -> void:
	var g := fixture()
	var actor: ResidentAnimator = g.workers[0].node
	g.focus = actor.position
	g.zoom = 30
	g._update_camera()
	check(actor.should_sample("walk", 0), "First distant pose sampled")
	check(not actor.should_sample("walk", .001), "Distant pose skips redundant evaluation")
	check(actor.should_sample("walk", .1), "Distant animation catches up to simulation time")
	check(actor.should_sample("pick_up", .72), "Exact pickup contact always sampled")
	check(actor.should_sample("pick_up", .721), "One-shot contact is never throttled")
	check(actor.should_sample("walk", 0), "Clip change samples immediately")
	check(actor.should_sample("walk", -.1), "Rewind samples immediately")
	g.focus = Vector3(500,0,500)
	g._update_camera()
	check(preload("res://scripts/visual_budget.gd").pixel_height(actor, 1.2) == 0, "Offscreen actor detected")
	check(not actor.should_sample("walk", 0), "Offscreen animation skips intermediate poses")
	check(actor.should_sample("walk", .3), "Offscreen pose periodically catches up")
	g.focus = actor.position
	g.zoom = 5
	g._update_camera()
	check(actor.should_sample("walk", .301), "Close-up restores full animation cadence")
	var mesh = actor.find_children("*", "MeshInstance3D", true, false)[0]
	check(is_equal_approx(mesh.lod_bias, .35), "Imported LOD uses reduced screen-space detail")
	g.zoom = 30
	g._update_camera()
	check(actor.should_sample("idle", 0, 10), "Real-time sampling starts")
	check(not actor.should_sample("idle", .06, 10.02), "Triple simulation speed does not triple visual work")
	check(actor.should_sample("idle", .12, 10.04), "Visual pose catches up at wall-clock cadence")
	g.queue_free()
	await process_frame
	print("VISUAL_BUDGET: %d failure(s)" % failures)
	quit(1 if failures else 0)
