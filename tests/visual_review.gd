extends SceneTree
## Repeatable visual/performance review in the real Compatibility renderer.
func _initialize() -> void:
	run.call_deferred()

func capture(path: String) -> void:
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.start_panel.hide()
	game.paused = true
	game.notice_timer = 0
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	await create_timer(2.0).timeout
	var intervals: Array[float] = []
	var previous := Time.get_ticks_usec()
	for i in range(120):
		await process_frame
		var now := Time.get_ticks_usec()
		intervals.append((now - previous) / 1000.0)
		previous = now
	intervals.sort()
	var sum := 0.0
	for ms in intervals: sum += ms
	print("VISUAL_REVIEW: average %.2f ms, p95 %.2f ms, screen %s" % [sum/intervals.size(),intervals[113],root.size])
	await capture("res://artifacts/ambiance-finition.png")
	game.yaw = -0.48
	await capture("res://artifacts/ambiance-angle.png")
	game.yaw = 0.05
	game.zoom = 15
	game.focus = Vector3(-4.6, 0, -3.7)
	await capture("res://artifacts/toile-detail.png")
	game.queue_free()
	await process_frame
	quit()
