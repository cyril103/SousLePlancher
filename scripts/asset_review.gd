extends Node3D
## Independent art review; open this scene and press F6.

const ASSET_PATH := "res://assets/models/reference_01/"
var camera: Camera3D
var yaw := 0.45
var pitch := 0.53
var distance := 6.5
var focus := Vector3(0, 0.65, 0)
var dragging := false
var residents: Array[Node3D] = []
var model_count := 0
var animation_count := 0

func _ready() -> void:
	var environment := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("202c29")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("b2c6bf")
	settings.ambient_light_energy = 0.32
	# Neutral sky reflections keep worn metal readable in Compatibility.
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("657c80")
	sky_material.sky_horizon_color = Color("b9beb4")
	sky_material.ground_bottom_color = Color("343a32")
	sky_material.ground_horizon_color = Color("999889")
	sky.sky_material = sky_material
	settings.sky = sky
	settings.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = settings
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -32, 0)
	light.light_color = Color("ffdfb0")
	light.light_energy = 0.85
	light.shadow_enabled = true
	add_child(light)
	var fill := OmniLight3D.new()
	fill.position = Vector3(3, 3, 2)
	fill.light_color = Color("b8d6ff")
	fill.light_energy = 0.35
	fill.omni_range = 10
	add_child(fill)
	for x in [-1.0, 1.0]:
		for z in [-1.0, 1.0]:
			add_asset("floor_module_2x2", Vector3(x, 0, z))
	residents.append(add_asset("resident_reference", Vector3(0.35, 0, 0.65), 0.14))
	add_asset("matchbox_bed", Vector3(-0.88, 0, -0.32), -0.04)
	add_asset("salvage_crate", Vector3(0.85, 0, -0.92), 0.18)
	add_asset("thimble_bucket", Vector3(1.02, 0, 0.35), -0.12)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = distance
	camera.near = 0.05
	add_child(camera)
	camera.make_current()
	update_camera()
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.07, 0.93)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var label := Label.new()
	label.text = "SOUS LE PLANCHER · LOT DE RÉFÉRENCE 01\nHabitant · Lit-allumettes · Seau-dé · Caisse · Plancher\n\nGlisser : tourner   |   Molette : zoomer\n1 : ensemble   2 : habitant   3 : mobilier\nF11 : plein écran   |   Échap : quitter\n\nÉtude 3D à valider · rig et animation de référence"
	label.add_theme_font_size_override("font_size", 17)
	panel.add_child(label)
	print("ASSET_REVIEW_READY: %d models, %d animated residents" % [model_count, animation_count])
	if "--capture-assets" in OS.get_cmdline_user_args():
		capture_review.call_deferred()

func add_asset(asset: String, location: Vector3, angle: float = 0.0) -> Node3D:
	var packed := load(ASSET_PATH + asset + ".glb") as PackedScene
	assert(packed != null, "Missing asset: " + asset)
	var instance := packed.instantiate() as Node3D
	assert(instance != null)
	add_child(instance)
	instance.position = location
	instance.rotation.y = angle
	model_count += 1
	for child in instance.find_children("*", "AnimationPlayer", true, false):
		var player := child as AnimationPlayer
		for animation_name in player.get_animation_list():
			if "idle_reference" in animation_name:
				player.get_animation(animation_name).loop_mode = Animation.LOOP_LINEAR
				player.play(animation_name)
				animation_count += 1
				break
	return instance

func update_camera() -> void:
	camera.size = distance
	camera.position = focus + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * 12
	camera.look_at(focus)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			dragging = event.pressed
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(1.6, distance - 0.35)
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(12, distance + 0.35)
		update_camera()
	elif event is InputEventMouseMotion and dragging:
		yaw -= event.relative.x * 0.008
		pitch = clampf(pitch + event.relative.y * 0.006, 0.12, 1.35)
		update_camera()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				get_tree().quit()
			KEY_F11:
				var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
			KEY_1:
				focus = Vector3(0, 0.65, 0)
				distance = 6.5
			KEY_2:
				focus = Vector3(0.35, 0.88, 0.65)
				distance = 2.5
				pitch = 0.25
			KEY_3:
				focus = Vector3(-0.7, 0.3, -0.3)
				distance = 3.4
		update_camera()

func capture_review() -> void:
	await get_tree().create_timer(2.0).timeout
	assert(model_count == 8)
	assert(animation_count == 1, "Resident reference animation did not import")
	DirAccess.make_dir_recursive_absolute("res://artifacts/reference_01")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/reference_01/godot_review.png")
	focus = Vector3(0.35, 0.88, 0.65)
	distance = 2.5
	pitch = 0.25
	update_camera()
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/reference_01/godot_resident.png")
	yaw = PI + residents[0].rotation.y
	pitch = 0.15
	update_camera()
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/reference_01/godot_resident_back.png")
	focus = Vector3(-0.75, 0.42, -0.3)
	distance = 3.0
	yaw = 0.65
	pitch = 0.55
	update_camera()
	await get_tree().create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://artifacts/reference_01/godot_matchbox.png")
	print("ASSET_REVIEW_CAPTURE_OK")
	get_tree().quit()
