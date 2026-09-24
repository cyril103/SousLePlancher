extends SceneTree
func _initialize() -> void:
	run.call_deferred()
func shot(game: Node, name: String) -> void:
	game._update_camera()
	game._refresh_ui()
	for i in range(5): await process_frame
	await create_timer(.2).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/checkpoint/" + name + ".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/checkpoint")
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "user://tests/checkpoint_visual_%d/colony.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.set_process(false)
	game.start_panel.hide()
	game.stock.food = 10000
	game.paused = false
	game.zoom = 16
	game.selected = 2
	game.assign_worker(0)
	for i in range(50): game.simulate(.05)
	game.request_checkpoint()
	game._show_tray("goals")
	await shot(game, "enregistrement_en_attente")
	for i in range(1500):
		game.simulate(.05)
		game._try_checkpoint()
		if not game.pending_save: break
	await shot(game, "sauvegarde")
	game.hud.ask_load()
	await shot(game, "confirmation")
	game.hud.cancel_load()
	var restored = game.load_checkpoint()
	if restored == null:
		quit(1)
		return
	game = restored
	game.set_process(false)
	game._show_tray("goals")
	await shot(game, "reprise")
	game.start_panel.show()
	game._show_tray("")
	await shot(game, "accueil")
	print("CHECKPOINT_VISUAL_OK")
	quit()
