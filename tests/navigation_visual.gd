extends SceneTree
func _initialize() -> void:
	run.call_deferred()

func shot(game: Node, name: String) -> void:
	game._update_camera()
	game._refresh_ui()
	game._update_routes(1.0)
	for i in range(4): await process_frame
	await create_timer(.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/navigation/" + name + ".png")

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/navigation")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.start_panel.hide()
	game.paused = false
	game.stock.food = 1000
	game._choose_build("workshop")
	assert(game._place_build(Vector3.ZERO))
	game.zoom = 16
	game.focus = Vector3(-1, 0, 0)
	game.show_paths = true
	for patch in [0, 2, 4, 1]:
		game.selected = patch
		game.assign_worker()
	game.simulate(.2)
	await shot(game, "contournement")
	for i in range(150): game.simulate(.05)
	game._show_tray("work")
	await shot(game, "travaux")
	game._toggle_hide()
	for i in range(650): game.simulate(.05)
	game._show_tray("")
	await shot(game, "refuge")
	print("NAVIGATION_VISUAL_OK")
	quit()
