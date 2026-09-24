extends Node3D
## Isolated animation laboratory, intentionally independent of colony AI.
const CLIPS := ["idle", "walk", "carry_walk", "work", "climb"]
const TITLES := ["Repos", "Marche", "Transport", "Travail au marteau", "Échelle"]
var actor: ResidentAnimator
var camera: Camera3D
var bench: Node3D
var ladder: Node3D
var label: Label
var selected := 0
var paused := false
var moving := true
var rate := 1.0
var elapsed := 0.0
var yaw := 0.65
var pitch := 0.28
var distance := 3.8
var dragging := false

func _ready() -> void:
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("1b2423")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b2c6bf")
	env.ambient_light_energy = 0.42
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -32, 0)
	light.light_color = Color("ffdfb0")
	light.light_energy = 0.95
	light.shadow_enabled = true
	add_child(light)
	var fill := OmniLight3D.new()
	fill.position = Vector3(2, 3, 3)
	fill.light_energy = 0.4
	fill.omni_range = 10
	add_child(fill)
	for z in [-2.0, 0.0, 2.0]:
		asset("reference_01/floor_module_2x2", Vector3(0, -0.055, z))
	bench = asset("refuge_02/salvage_workbench", Vector3(0, 0, -0.75))
	ladder = asset("refuge_02/ladder_2m", Vector3.ZERO)
	actor = ResidentAnimator.new()
	add_child(actor)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.05
	add_child(camera)
	camera.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_top = -95
	layer.add_child(panel)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.055, 0.05, 0.95)
	style.content_margin_left = 24
	style.content_margin_top = 10
	panel.add_theme_stylebox_override("panel", style)
	label = Label.new()
	label.add_theme_font_size_override("font_size", 17)
	panel.add_child(label)
	choose(1)
	print("ANIMATION_REVIEW_READY: 5 clips, ", actor.skeleton.get_bone_count(), " bones")
	if "--capture-animations" in OS.get_cmdline_user_args():
		capture.call_deferred()

func asset(path: String, at: Vector3) -> Node3D:
	var instance := (load("res://assets/models/" + path + ".glb") as PackedScene).instantiate() as Node3D
	add_child(instance)
	instance.position = at
	return instance

func choose(index: int) -> void:
	selected = index
	elapsed = 0
	actor.position = Vector3.ZERO
	actor.rotation.y = PI if index >= 3 else 0.0
	actor.set_action(CLIPS[index])
	actor.player.seek(0, true)
	actor.player.advance(0)
	bench.visible = index == 3
	ladder.visible = index == 4
	yaw = -1.15 if index == 3 else 0.65
	refresh_label()

func refresh_label() -> void:
	label.text = "LOT 03 · %s · ×%.2f%s\n1 Repos   2 Marche   3 Transport   4 Travail   5 Échelle   |   Espace : pause   |   −/+ : vitesse\nD : déplacement %s   |   Glisser : tourner   Molette : zoom   F11 : plein écran   Échap : fermer" % [TITLES[selected], rate, " · PAUSE" if paused else "", "actif" if moving else "sur place"]

func _process(delta: float) -> void:
	if not is_instance_valid(actor):
		return
	actor.player.speed_scale = 0.0 if paused else rate
	if not paused:
		elapsed += delta * rate
	if selected in [1, 2] and moving:
		# A review runway repeats at its edge; this is not a navigation turn.
		actor.position.z = fposmod(elapsed * float(ResidentAnimator.SPEEDS[CLIPS[selected]]), 3.0) - 1.5
	elif selected == 4 and moving:
		# Three complete cycles up, then reverse along the same rungs.
		var phase := fposmod(elapsed, 9.6)
		var ascent := phase < 4.8
		var height := (phase if ascent else 9.6 - phase) * 0.31875
		actor.position = Vector3(0, height, 0.36 - 0.19 * height)
		actor.player.speed_scale *= 1.0 if ascent else -1.0
	else:
		actor.position = Vector3(0, 0, 0.36) if selected == 4 else Vector3.ZERO
	update_camera()

func update_camera() -> void:
	var focus := actor.position + Vector3(0, 0.85, 0)
	camera.size = distance
	camera.position = focus + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * 12
	camera.look_at(focus)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			dragging = event.pressed
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(2.1, distance - 0.25)
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(8.0, distance + 0.25)
	elif event is InputEventMouseMotion and dragging:
		yaw -= event.relative.x * 0.008
		pitch = clampf(pitch + event.relative.y * 0.006, 0.1, 1.3)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_5:
			choose(event.keycode - KEY_1)
		match event.keycode:
			KEY_SPACE: paused = not paused
			KEY_D: moving = not moving
			KEY_MINUS: rate = maxf(0.25, rate - 0.25)
			KEY_EQUAL, KEY_PLUS: rate = minf(2.0, rate + 0.25)
			KEY_ESCAPE: get_tree().quit()
			KEY_F11:
				var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
		refresh_label()

func capture() -> void:
	await get_tree().create_timer(1.0).timeout
	assert(actor.skeleton.get_bone_count() == 21)
	# Detect a frozen export and foot sliding during the planted portion.
	for clip in ["walk", "carry_walk"]:
		actor.player.play(clip, 0.0)
		var planted: Array[Vector3] = []
		for time in [0.12, 0.36]:
			actor.player.seek(time, true)
			actor.player.advance(0)
			var foot := actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("L_foot")).origin
			foot.z += time * float(ResidentAnimator.SPEEDS[clip])
			planted.append(foot)
		assert(planted[0].distance_to(planted[1]) < 0.012, "Planted foot slides: " + clip)
	var lengths := [4.0, 1.2, 1.4, 1.2, 1.6]
	DirAccess.make_dir_recursive_absolute("res://artifacts/animations_03")
	moving = false
	for i in range(5):
		choose(i)
		actor.player.play(CLIPS[i], 0.0)
		assert(absf(actor.player.get_animation(CLIPS[i]).length - lengths[i]) < 0.04)
		assert(actor.cargo.visible == (i == 2))
		assert(actor.tool.visible == (i == 3))
		for sample in [0.15, 0.55]:
			paused = true
			actor.player.seek(lengths[i] * sample, true)
			actor.player.advance(0)
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://artifacts/animations_03/%s_%d.png" % [CLIPS[i], int(sample * 100)])
	print("ANIMATION_REVIEW_CHECKS_OK: clips, durations, rig, attachments, 10 captures")
	get_tree().quit()
