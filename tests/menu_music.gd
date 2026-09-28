extends SceneTree
var failures := 0

func _initialize() -> void: run.call_deferred()

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func run() -> void:
	var music = root.get_node("MenuMusic")
	music.settings_path = "user://music_test_%d.cfg" % Time.get_ticks_usec()
	music.enabled = true
	check(music.player.stream is AudioStreamOggVorbis, "Imported runtime music is Ogg Vorbis")
	check(music.player.stream.loop, "Music loops through the importer settings")
	check(absf(music.player.stream.get_length() - 80.0) < .02, "Loop lasts exactly 32 bars / 80 seconds")
	var splash = load("res://scenes/startup.tscn").instantiate()
	splash.history_path = "user://music_startup_test_%d.cfg" % Time.get_ticks_usec()
	var splash_history: String = splash.history_path
	splash.auto_advance = false
	root.add_child(splash)
	current_scene = splash
	await create_timer(.5).timeout
	check(music.player.playing, "Splash starts music")
	var player_id: int = music.player.get_instance_id()
	var before: float = music.player.get_playback_position()
	for i in range(1800):
		await process_frame
		if splash.next_scene != null: break
	check(splash.next_scene != null, "Menu scene loads")
	splash.skip_requested = true
	splash.auto_advance = true
	for i in range(1800):
		await process_frame
		if not is_instance_valid(splash): break
	check(current_scene != null and current_scene.scene_file_path == "res://scenes/main.tscn", "Splash reaches actual welcome menu")
	check(music.player.get_instance_id() == player_id and music.player.playing, "Same player survives the scene change")
	check(music.player.get_playback_position() >= before, "Welcome menu does not restart the track")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://artifacts/menu_music.png")
	# Toggle persistence is confined to a unique test file.
	music.toggle_enabled()
	await create_timer(1.7).timeout
	check(not music.player.playing, "Muting fades out and stops playback")
	var settings := ConfigFile.new()
	check(settings.load(music.settings_path) == OK and settings.get_value("music", "enabled", true) == false, "Mute preference is saved separately from the colony")
	music.toggle_enabled()
	check(music.player.playing, "Unmuting in menu resumes music")
	# Founding or restoring a colony hides this same panel.
	current_scene.start_panel.hide()
	await create_timer(1.7).timeout
	check(not music.player.playing and not music.menu_active, "Entering gameplay fades out the menu theme")
	current_scene.start_panel.show()
	check(music.player.playing, "Returning to welcome can restart music")
	music.stop_menu()
	await create_timer(.1).timeout
	music.start_menu()
	await create_timer(1.7).timeout
	check(music.player.playing, "An interrupted fade cannot stop newly restarted menu music")
	# Exercise the actual Vorbis wrap without waiting eighty seconds.
	music.player.seek(79.8)
	await create_timer(.5).timeout
	check(music.player.playing and music.player.get_playback_position() < 2.0, "Vorbis loops past its end while remaining active")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(music.settings_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(splash_history))
	current_scene.queue_free()
	await process_frame
	music.player.stop()
	print("MENU_MUSIC: %d failure(s)" % failures)
	quit(1 if failures else 0)
