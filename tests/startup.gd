extends SceneTree
const Startup = preload("res://scripts/startup.gd")
var failures := 0
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 100
	var seen := {}
	for previous in range(-1, 5):
		for i in range(80):
			var chosen := Startup.choose_index(previous, rng)
			check(chosen >= 0 and chosen < 5 and chosen != previous, "Random choice excludes previous image")
			seen[chosen] = true
	check(seen.size() == 5, "Every proposal is reachable")
	for path in Startup.IMAGES: check(load(path) is Texture2D, "Packaged splash texture loads: " + path)
	var path := "user://startup_test_%d.cfg" % Time.get_ticks_usec()
	var previous := -1
	for launch in range(2):
		var splash = load("res://scenes/startup.tscn").instantiate()
		splash.history_path = path
		splash.auto_advance = false
		root.add_child(splash)
		check(splash.selected_index != previous, "Relaunch reads history and avoids repetition")
		previous = splash.selected_index
		check(splash.artwork.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_CENTERED, "Artwork retains full composition")
		for i in range(1800):
			await process_frame
			if splash.next_scene != null or splash.failed: break
		check(splash.next_scene != null and not splash.failed, "Actual game scene finishes loading")
		if launch == 0:
			splash.queue_free()
			await process_frame
		else:
			current_scene = splash
			var event := InputEventKey.new()
			event.keycode = KEY_SPACE
			event.pressed = true
			splash._input(event)
			check(splash.skip_requested, "Space requests skip")
			splash.auto_advance = true
			for i in range(1800):
				await process_frame
				if not is_instance_valid(splash): break
			check(not is_instance_valid(splash), "Splash is removed after transition")
			check(current_scene != null and current_scene.scene_file_path == "res://scenes/main.tscn", "Transition reaches actual main scene")
			if current_scene != null and current_scene.scene_file_path == "res://scenes/main.tscn":
				check(current_scene.start_panel.visible, "Welcome screen remains available after startup")
			current_scene.queue_free()
			await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("STARTUP: %d failure(s)" % failures)
	quit(1 if failures else 0)
