extends SceneTree
const Soundscape = preload("res://scripts/world_soundscape.gd")
var failures := 0
var events: Array[Dictionary] = []

func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func stop_voices(s: Node) -> void:
	for voice in s.voices: voice.stop()
func count_kind(kind: String) -> int:
	var count := 0
	for event in events:
		if event.kind == kind: count += 1
	return count
func run() -> void:
	var g = load("res://scenes/main.tscn").instantiate()
	g.set_meta("restore_mode", true)
	root.add_child(g)
	g.set_process(false)
	var s = g.soundscape
	s.enabled = true
	s.volume = .7
	s.settings_path = "user://soundscape_test_%d.cfg" % Time.get_ticks_usec()
	s.rng.seed = 55001
	s.sound_played.connect(func(kind: String, variant: int, point: Vector3): events.append({"kind": kind, "variant": variant, "point": point}))
	for kind in s.COUNTS:
		check(s.bank[kind].size() == s.COUNTS[kind], "All variants load: " + kind)
		for stream in s.bank[kind]: check(stream is AudioStreamWAV and stream.get_length() > .02, "Valid WAV: " + kind)
		var previous := -1
		for i in range(100):
			var selected: int = s.select_variant(kind)
			check(selected != previous and selected >= 0 and selected < s.COUNTS[kind], "No immediate repetition: " + kind)
			previous = selected
	check(s.air.stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Room bed loops")
	check(s.fires[0].stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "Flames loop")
	s.update(.1)
	check(not s.air.playing and events.is_empty(), "Welcome stays free of gameplay ambience")
	g.start_panel.hide()
	g.paused = false
	s.update(.1)
	var state: String = g.Save.Live.capture(g).sha256
	seed(553)
	var expected_random := randi()
	seed(553)
	s.update(.3)
	check(randi() == expected_random, "Audio has an independent RNG")
	check(g.Save.Live.capture(g).sha256 == state, "Audio observation cannot alter checkpoint state")
	check(s.listener.global_position.is_equal_approx(g.focus + Vector3.UP * 1.5), "Listener follows camera focus, not the distant camera")
	check(not s.play("hammer", Vector3(400, 0, 0)), "Distant sounds do not occupy a voice")
	check(s.play("hammer", g.focus, true), "Sheltered Foley plays")
	var found := false
	for voice in s.voices:
		if voice.playing and voice.get_meta("kind", "") == "hammer": found = voice.bus == s.MUFFLED
	check(found, "Refuge walls route sound through the muffled bus")
	stop_voices(s)
	for kind in ["step", "hammer", "crate", "fiber", "crumb", "water"]:
		for i in range(6): s.play(kind, g.focus)
	var active := 0
	for voice in s.voices:
		if voice.playing: active += 1
	check(active <= s.LOCAL_VOICES, "Local polyphony is bounded")
	check(s.play("giant", g.focus + Vector3.UP * 4), "Human footsteps retain reserved voices under load")
	stop_voices(s)
	g.paused = true
	var before := events.size()
	s.update(10)
	check(events.size() == before, "Pause never schedules work or footsteps")
	g.paused = false
	g.elapsed = 67.9
	s.update(.05)
	var giants := count_kind("giant")
	g.elapsed = 68.1
	s.update(.05)
	s.update(.2)
	check(count_kind("giant") == giants + 1, "Human footstep begins inside the danger window")
	g.elapsed = 88.1
	giants = count_kind("giant")
	s.update(2)
	check(count_kind("giant") == giants, "No new human footsteps after the passage")
	stop_voices(s)
	g.elapsed = 70
	s.update(.2)
	before = events.size()
	for i in range(10):
		g.elapsed += .3 # x3 simulation, constant real-time sound density.
		s.update(.1)
	check(events.size() - before <= 4, "Accelerated play does not create a burst of giant footsteps")
	stop_voices(s)
	g.elapsed = 3
	s.update(.1)
	before = events.size()
	s.update(.1)
	check(events.size() == before, "Clock rewind does not replay missed actions")
	check(Soundscape.crossed(.2, .4, .336) and Soundscape.crossed(1.1, .4, .336), "Hammer marker works across animation wrap")
	check(not Soundscape.crossed(.4, .5, .336), "Hammer does not repeat after contact")
	g.kitchen.tasks[0] = {"stage": "harvest"}
	check(s.work_sound(0) == "crumb", "Kitchen harvesting is not mistaken for hammering")
	g.kitchen.tasks.erase(0)
	g.fissure.missions[0] = {"phase": "harvest"}
	check(s.work_sound(0) == "fiber", "Alcove harvesting uses fibre Foley")
	g.fissure.missions.erase(0)

	# Actual colony: physical delivery, gathering and construction, no fabricated states.
	s.silence()
	events.clear()
	g.prepare_soundscape_demo()
	g.elapsed = 0
	g.event_index = 0
	for i in range(1800):
		g.simulate(.05)
		g.suspicion = 0
		s.update(.05)
		# Fast-forwarded simulation is faster than the audio device; release finished
		# audition windows explicitly so this integration test can observe later work.
		if i % 20 == 0:
			stop_voices(s)
			await process_frame
		if count_kind("hammer") > 0 and count_kind("crate") > 1 and count_kind("scrape") > 0: break
	check(count_kind("step") > 0, "Real movement emits resident footsteps")
	check(count_kind("crate") > 1, "Real carrying changes emit crate Foley")
	check(count_kind("scrape") > 0 or count_kind("fiber") > 0, "Actual gathering has resource-specific Foley")
	check(count_kind("hammer") > 0, "Actual construction emits contact-timed hammer blows")
	var first_hammer := -1
	for i in range(events.size()):
		if events[i].kind == "hammer": first_hammer = i; break
	check(first_hammer > 0, "Construction sound follows deliveries rather than blueprint placement")
	s.toggle_enabled()
	check(not s.enabled and not s.air.playing, "Mute stops sound beds immediately")
	before = events.size()
	s.update(1)
	check(events.size() == before, "Muted observer stays silent")
	s.set_volume(.25)
	var config := ConfigFile.new()
	check(config.load(s.settings_path) == OK and config.get_value("ambience", "enabled", true) == false and is_equal_approx(config.get_value("ambience", "volume", 1.0), .25), "Preferences persist outside colony saves")
	s.enabled = true
	s.volume = 0
	s.update(.1)
	check(not s.air.playing, "Zero volume is silent")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(s.settings_path))
	g.queue_free()
	await process_frame
	print("WORLD_SOUNDSCAPE: %d failure(s)" % failures)
	quit(1 if failures else 0)
