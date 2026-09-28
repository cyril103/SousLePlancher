extends Node3D
## Presentation only: observes simulation/animation, never changes colony state or RNG.
signal sound_played(kind: String, variant: int, point: Vector3)
signal settings_changed
const ROOT := "res://assets/audio/ambience/"
const COUNTS := {"giant": 5, "step": 5, "hammer": 5, "crate": 5, "fiber": 5, "crumb": 5, "creak": 5, "scrape": 3, "water": 3, "door": 2}
const LEVELS := {"giant": -1.0, "step": -7.0, "hammer": -3.0, "crate": -5.0, "fiber": -9.0, "crumb": -9.0, "creak": -5.0, "scrape": -7.0, "water": -7.0, "door": -7.0}
const MASTER := "WorldSound"
const NEAR := "ColonyFoley"
const MUFFLED := "ColonySheltered"
const ABOVE := "HouseAbove"
const LOCAL_VOICES := 10
const TOTAL_VOICES := 14
const IMPACT := .336 # Authored hammer contact in the 1.2-second work animation.
var game: Node3D
var settings_path := "user://ambience.cfg"
var enabled := true
var volume := .7
var rng := RandomNumberGenerator.new()
var bank: Dictionary = {}
var last_variant: Dictionary = {}
var voices: Array[AudioStreamPlayer3D] = []
var fires: Array[AudioStreamPlayer3D] = []
var air: AudioStreamPlayer
var listener: AudioListener3D
var previous: Dictionary = {}
var cooldowns: Dictionary = {}
var wall_clock := 0.0
var giant_wait := 0.0
var creak_wait := 8.0
var was_danger := false
var previous_elapsed := -1.0
var previous_door := -1.0
var door_wait := 0.0
var active := false
var closing := false

func _ready() -> void:
	rng.randomize()
	var config := ConfigFile.new()
	if config.load(settings_path) == OK:
		var stored = config.get_value("ambience", "enabled", true)
		if stored is bool: enabled = stored
		stored = config.get_value("ambience", "volume", .7)
		if (stored is float or stored is int) and is_finite(float(stored)): volume = clampf(float(stored), 0, 1)
	make_buses()
	for kind in COUNTS:
		bank[kind] = []
		for i in range(COUNTS[kind]): bank[kind].append(load(ROOT + "%s_%02d.wav" % [kind, i]))
	listener = AudioListener3D.new()
	add_child(listener)
	listener.make_current()
	for i in range(TOTAL_VOICES):
		var voice := AudioStreamPlayer3D.new()
		voice.unit_size = 5.0
		voice.max_db = 0.0
		voice.attenuation_filter_cutoff_hz = 7500
		voice.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
		add_child(voice)
		voices.append(voice)
	air = AudioStreamPlayer.new()
	air.stream = loop_stream("room_00.wav")
	air.bus = MASTER
	air.volume_db = -13.0
	add_child(air)
	for i in range(3):
		var fire := AudioStreamPlayer3D.new()
		fire.stream = loop_stream("fire_00.wav")
		fire.bus = NEAR
		fire.unit_size = 3.5
		fire.max_distance = 12.0
		fire.volume_db = -16.0
		add_child(fire)
		fires.append(fire)
	apply_settings()

func loop_stream(filename: String) -> AudioStreamWAV:
	var stream := load(ROOT + filename).duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	return stream

func make_bus(name_: String, send: String) -> int:
	var index := AudioServer.get_bus_index(name_)
	if index < 0:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, name_)
		AudioServer.set_bus_send(index, send)
	return index

func make_buses() -> void:
	var index := make_bus(MASTER, "Master")
	if AudioServer.get_bus_effect_count(index) == 0:
		# Midrange presence survives small speakers; the limiter remains last.
		var presence := AudioEffectEQ6.new()
		presence.set_band_gain_db(2, 2.0)
		presence.set_band_gain_db(3, 3.0)
		presence.set_band_gain_db(4, 1.5)
		AudioServer.add_bus_effect(index, presence)
		var limiter := AudioEffectLimiter.new()
		AudioServer.add_bus_effect(index, limiter)
	index = make_bus(NEAR, MASTER)
	if AudioServer.get_bus_effect_count(index) == 0:
		var room := AudioEffectReverb.new()
		room.room_size = .48
		room.damping = .8
		room.wet = .12
		AudioServer.add_bus_effect(index, room)
	index = make_bus(MUFFLED, NEAR)
	if AudioServer.get_bus_effect_count(index) == 0:
		var wall := AudioEffectLowPassFilter.new()
		wall.cutoff_hz = 1600
		AudioServer.add_bus_effect(index, wall)
	index = make_bus(ABOVE, MASTER)
	if AudioServer.get_bus_effect_count(index) == 0:
		var floor_ := AudioEffectLowPassFilter.new()
		floor_.cutoff_hz = 2200
		AudioServer.add_bus_effect(index, floor_)
		var room := AudioEffectReverb.new()
		room.room_size = .7
		room.wet = .14
		AudioServer.add_bus_effect(index, room)

func apply_settings() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(MASTER), linear_to_db(maxf(.0001, volume)))
	if not enabled or volume <= 0: silence()
	settings_changed.emit()

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("ambience", "enabled", enabled)
	config.set_value("ambience", "volume", volume)
	config.save(settings_path)
	apply_settings()

func toggle_enabled() -> void:
	enabled = not enabled
	save_settings()

func set_volume(value: float) -> void:
	if not is_finite(value): return
	volume = clampf(value, 0, 1)
	save_settings()

func silence() -> void:
	active = false
	previous.clear()
	previous_door = -1
	previous_elapsed = -1
	was_danger = false
	if is_instance_valid(air): air.stop()
	for voice in voices: voice.stop()
	for fire in fires: fire.stop()

func _exit_tree() -> void:
	silence()
	for voice in voices: voice.stream = null
	for fire in fires: fire.stream = null
	if is_instance_valid(air): air.stream = null

func shutdown_and_quit() -> void:
	if closing: return
	closing = true
	game.set_process(false)
	# Let the audio thread retire its WAV playback objects before engine teardown.
	var tree := get_tree()
	var fade := create_tween()
	fade.tween_method(func(db: float): AudioServer.set_bus_volume_db(0, db), AudioServer.get_bus_volume_db(0), -70.0, .12)
	await fade.finished
	silence()
	var music := get_node_or_null("/root/MenuMusic")
	if music != null: music.player.stop()
	await tree.create_timer(.10).timeout
	tree.quit()

static func crossed(before: float, after: float, marker: float) -> bool:
	if after < before: return marker > before or marker <= after
	return before < marker and after >= marker

func select_variant(kind: String) -> int:
	var count: int = COUNTS[kind]
	var old: int = last_variant.get(kind, -1)
	var selected := rng.randi_range(0, count - 2 if old >= 0 else count - 1)
	if old >= 0 and selected >= old: selected += 1
	last_variant[kind] = selected
	return selected

func play(kind: String, point: Vector3, sheltered := false, gain := 0.0) -> bool:
	if not active or not enabled or volume <= 0 or not COUNTS.has(kind): return false
	var overhead := kind in ["giant", "creak"]
	var distance := 55.0 if overhead else 22.0
	if point.distance_to(listener.global_position) > distance: return false
	var count := 0
	for voice in voices:
		if voice.playing and voice.get_meta("kind", "") == kind: count += 1
	if count >= (3 if kind in ["step", "creak"] else 2): return false
	for i in range(LOCAL_VOICES if overhead else 0, TOTAL_VOICES if overhead else LOCAL_VOICES):
		var voice := voices[i]
		if voice.playing: continue
		var variant := select_variant(kind)
		voice.stream = bank[kind][variant]
		voice.bus = ABOVE if overhead else (MUFFLED if sheltered else NEAR)
		voice.max_distance = distance
		voice.unit_size = 7.0 if overhead else 5.0
		voice.position = point
		voice.volume_db = LEVELS[kind] + rng.randf_range(-1.1, 1.1) + gain - (4.0 if sheltered else 0.0)
		voice.pitch_scale = rng.randf_range(.95, 1.05)
		voice.set_meta("kind", kind)
		voice.stream_paused = false
		voice.play()
		sound_played.emit(kind, variant, point)
		return true
	return false

func update(delta: float) -> void:
	if not is_instance_valid(game.start_panel): return
	listener.global_transform = game.camera.global_transform
	listener.global_position = game.focus + Vector3.UP * 1.5
	if not enabled or volume <= 0 or game.start_panel.visible or game.ended:
		if active: silence()
		return
	active = true
	if not air.playing: air.play()
	air.volume_db = move_toward(air.volume_db, -19.0 if game.paused else -13.0, delta * 10)
	for voice in voices: voice.stream_paused = game.paused
	for fire in fires: fire.stream_paused = game.paused
	if game.paused:
		previous.clear()
		previous_door = game.refuge.opening
		previous_elapsed = game.elapsed
		return
	# Real time controls density; x3 speed never triples playback pitch or floods voices.
	wall_clock += delta
	var jumped: bool = previous_elapsed >= 0 and (game.elapsed < previous_elapsed or game.elapsed - previous_elapsed > 1.0)
	previous_elapsed = game.elapsed
	if jumped:
		previous.clear()
		previous_door = game.refuge.opening
		giant_wait = .3
	var phase: float = fposmod(game.elapsed, 100.0)
	var danger := phase >= 68 and phase < 88
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(NEAR), -3.0 if danger else 0.0)
	if danger:
		giant_wait -= delta
		if not was_danger: giant_wait = .15
		if giant_wait <= 0:
			var point := Vector3(lerpf(-14, 14, (phase - 68) / 20), 4.2, 1.5 + sin(phase * .3) * 2)
			play("giant", point)
			if rng.randf() < .62: play("creak", point + Vector3(.4, 0, .2), false, -2.0)
			giant_wait = rng.randf_range(.64, .91)
	was_danger = danger
	creak_wait -= delta
	if creak_wait <= 0:
		if not danger: play("creak", Vector3(rng.randf_range(-12, 12), 4, rng.randf_range(-6, 8)), false, -10)
		creak_wait = rng.randf_range(9, 19)
	update_workers()
	door_wait = maxf(0, door_wait - delta)
	var opening: float = game.refuge.opening
	if previous_door >= 0 and door_wait <= 0:
		if (previous_door < .1 and opening >= .1) or (previous_door > .9 and opening <= .9):
			play("door", game.HOME + Vector3(0, .5, 1))
			door_wait = .7
	previous_door = opening
	update_flames()

func update_workers() -> void:
	for index in range(game.workers.size()):
		var w: Dictionary = game.workers[index]
		var actor = w.node
		var controller = w.delivery
		var point: Vector3 = actor.position
		var clip: String = actor.current
		var phase: float = actor.player.current_animation_position
		var snapshot := {"pos": point, "clip": clip, "phase": phase, "cargo": w.carrying, "state": controller.state, "walk": 0.0}
		if not previous.has(index):
			previous[index] = snapshot
			continue
		var old: Dictionary = previous[index]
		var distance: float = point.distance_to(old.pos)
		var sheltered: bool = controller.inside_refuge and not game.refuge.cutaway
		if distance < 1.2 and distance > .0001 and clip in ["walk", "torch_walk", "carry_walk", "climb", "climb_down", "health_pull"]:
			snapshot.walk = old.walk + distance
			if snapshot.walk >= .65 and wall_clock >= cooldowns.get("step%d" % index, 0.0):
				play("step", point, sheltered, -2.0 if controller.climbing else 0.0)
				snapshot.walk = fmod(snapshot.walk, .65)
				cooldowns["step%d" % index] = wall_clock + .16
		elif distance <= .0001 and clip == old.clip: snapshot.walk = old.walk
		if clip == "work" and old.clip == "work" and crossed(old.phase, phase, IMPACT):
			if wall_clock >= cooldowns.get("work%d" % index, 0.0):
				play(work_sound(index), point, sheltered)
				cooldowns["work%d" % index] = wall_clock + .24
		if w.carrying != old.cargo and (w.carrying > 0 or old.cargo > 0):
			play("crate", point, sheltered, -3.0 if w.carrying > old.cargo else 0.0)
		if controller.state == "gather" and wall_clock >= cooldowns.get("gather%d" % index, 0.0):
			var kind: String = {"wood": "scrape", "fiber": "fiber", "food": "crumb", "water": "water"}.get(w.kind, "fiber")
			play(kind, point, sheltered)
			cooldowns["gather%d" % index] = wall_clock + rng.randf_range(.7, 1.15)
		previous[index] = snapshot

func work_sound(owner: int) -> String:
	# The same visual work clip also gathers biscuit/fibre: those are not hammers.
	if game.kitchen.tasks.get(owner, {}).get("stage", "") == "harvest": return "crumb"
	if game.fissure.missions.get(owner, {}).get("phase", "") == "harvest": return "fiber"
	if game.torches.crafting.has(owner):
		var order: Dictionary = game.torches.orders[game.torches.crafting[owner]]
		if order.get("refill", -1) >= 0: return "fiber"
	return "hammer"

func update_flames() -> void:
	var points: Array[Vector3] = []
	for torch in game.get_node("Atmosphere").torches:
		if torch.is_visible_in_tree(): points.append(torch.global_position)
	for w in game.workers:
		if w.node.torch_light.visible or w.node.lantern_light.visible: points.append(w.node.position + Vector3.UP)
	points.sort_custom(func(a: Vector3, b: Vector3): return a.distance_squared_to(listener.global_position) < b.distance_squared_to(listener.global_position))
	for i in range(fires.size()):
		var fire := fires[i]
		if i >= points.size() or points[i].distance_to(listener.global_position) >= fire.max_distance:
			fire.stop()
			continue
		fire.position = points[i]
		if not fire.playing: fire.play(rng.randf_range(0, 20))
