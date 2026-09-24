extends Node3D
## Refuge assembly review; no construction or pathfinding gameplay yet.

var camera: Camera3D
var yaw := 0.55
var pitch := 0.60
var distance := 10.5
var focus := Vector3(1.4, 0.8, 0)
var dragging := false
var door: Node3D
var door_open := true
var door_tween: Tween
var key_light: DirectionalLight3D
var environment: Environment
var warm_lights: Array[OmniLight3D] = []
var ambiance := false
var model_count := 0
var animated_count := 0
var walls: Array[Node3D] = []
var walls_visible := true

func _ready() -> void:
	setup_lighting()
	for x in [-2.0, 0.0, 2.0]:
		for z in [-1.0, 1.0]:
			asset("reference_01", "floor_module_2x2", Vector3(x, 0, z))
	walls.append(asset("refuge_02", "wall_solid_2m", Vector3(-2, 0, -2)))
	walls.append(asset("refuge_02", "wall_doorway_2m", Vector3(0, 0, -2)))
	walls.append(asset("refuge_02", "wall_window_2m", Vector3(2, 0, -2)))
	for z in [-1.0, 1.0]:
		walls.append(asset("refuge_02", "wall_solid_2m", Vector3(-3, 0, z), PI / 2))
	walls.append(asset("refuge_02", "wall_window_2m", Vector3(3, 0, -1), PI / 2))
	door = asset("refuge_02", "door_leaf_1m", Vector3(-0.505, 0, -1.925), deg_to_rad(-100))
	asset("reference_01", "matchbox_bed", Vector3(-2, 0, -0.2))
	asset("reference_01", "resident_reference", Vector3(-0.15, 0, 0.75), -0.35)
	asset("refuge_02", "salvage_workbench", Vector3(0, 0, -0.8))
	asset("reference_01", "thimble_bucket", Vector3(-1.1, 0, 0.85))
	asset("refuge_02", "ladder_2m", Vector3(2, 0, 0))
	asset("reference_01", "floor_module_2x2", Vector3(2, 2.2, -1))
	asset("reference_01", "salvage_crate", Vector3(2.25, 2.2, -1.2), -0.14)
	asset("refuge_02", "bridge_2m", Vector3(4, 0, 1), PI / 2)
	asset("reference_01", "floor_module_2x2", Vector3(6, 0, 1))
	asset("reference_01", "salvage_crate", Vector3(6.35, 0, 0.65), 0.15)
	asset("reference_01", "salvage_crate", Vector3(5.65, 0, 1.25), -0.2)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.near = 0.05
	add_child(camera)
	camera.make_current()
	update_camera()
	setup_ui()
	print("REFUGE_REVIEW_READY: %d instances, %d animated residents" % [model_count, animated_count])
	if "--capture-refuge" in OS.get_cmdline_user_args():
		capture_review.call_deferred()

func asset(folder: String, model: String, location: Vector3, angle: float = 0.0) -> Node3D:
	var packed := load("res://assets/models/%s/%s.glb" % [folder, model]) as PackedScene
	assert(packed != null, "Missing asset " + model)
	var instance := packed.instantiate() as Node3D
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
				animated_count += 1
				break
	return instance

func setup_lighting() -> void:
	var world := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("182320")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("a8bbb1")
	environment.ambient_light_energy = 0.32
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("657c80")
	sky_material.sky_horizon_color = Color("b9beb4")
	sky_material.ground_bottom_color = Color("343a32")
	sky_material.ground_horizon_color = Color("999889")
	sky.sky_material = sky_material
	environment.sky = sky
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	world.environment = environment
	add_child(world)
	key_light = DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-52, -28, 0)
	key_light.light_color = Color("ffe2b5")
	key_light.light_energy = 0.8
	key_light.shadow_enabled = true
	add_child(key_light)
	for point in [Vector3(-2, 1.5, -0.3), Vector3(0, 1.7, -0.8), Vector3(2, 1.6, 0.7)]:
		var light := OmniLight3D.new()
		light.position = point
		light.light_color = Color("ffb55f")
		light.light_energy = 0.0
		light.omni_range = 3.5
		light.shadow_enabled = true
		add_child(light)
		warm_lights.append(light)

func setup_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(20, 20)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.06, 0.05, 0.94)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var label := Label.new()
	label.text = "SOUS LE PLANCHER · KIT DE REFUGE\nMurs · Porte · Échelle · Passerelle · Établi\n\nGlisser : tourner  |  Molette : zoomer\n1 : ensemble  2 : atelier  3 : accès\nEspace : porte  |  M : masquer les murs\nL : lumière de revue / ambiance\nF11 : plein écran  |  Échap : quitter\n\nAssemblage de référence · grille de 2 unités"
	label.add_theme_font_size_override("font_size", 16)
	panel.add_child(label)

func update_camera() -> void:
	camera.size = distance
	camera.position = focus + Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * 18
	camera.look_at(focus)

func toggle_door() -> void:
	door_open = not door_open
	if door_tween and door_tween.is_valid():
		door_tween.kill()
	door_tween = create_tween()
	door_tween.tween_property(door, "rotation:y", deg_to_rad(-100) if door_open else 0.0, 0.6)

func toggle_lighting() -> void:
	ambiance = not ambiance
	environment.ambient_light_energy = 0.12 if ambiance else 0.32
	key_light.light_energy = 0.16 if ambiance else 0.8
	for light in warm_lights:
		light.light_energy = 1.1 if ambiance else 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_MIDDLE]:
			dragging = event.pressed
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			distance = maxf(2.5, distance - 0.45)
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			distance = minf(18, distance + 0.45)
		update_camera()
	elif event is InputEventMouseMotion and dragging:
		yaw -= event.relative.x * 0.008
		pitch = clampf(pitch + event.relative.y * 0.006, 0.14, 1.4)
		update_camera()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE: get_tree().quit()
			KEY_SPACE: toggle_door()
			KEY_L: toggle_lighting()
			KEY_M:
				walls_visible = not walls_visible
				for wall in walls: wall.visible = walls_visible
				door.visible = walls_visible
			KEY_F11:
				var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
			KEY_1:
				focus = Vector3(1.4, 0.8, 0)
				distance = 10.5
			KEY_2:
				focus = Vector3(-0.35, 0.8, -0.65)
				distance = 4.4
			KEY_3:
				focus = Vector3(3.5, 1.0, 0.5)
				distance = 6.5
		update_camera()

func screenshot(path: String) -> void:
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)

func capture_review() -> void:
	await get_tree().create_timer(2.0).timeout
	assert(model_count == 24, "Unexpected assembly count")
	assert(animated_count == 1)
	DirAccess.make_dir_recursive_absolute("res://artifacts/refuge_02")
	await screenshot("res://artifacts/refuge_02/ensemble.png")
	toggle_door()
	await get_tree().create_timer(0.8).timeout
	assert(absf(door.rotation.y) < 0.001, "Door did not close")
	toggle_door()
	await get_tree().create_timer(0.8).timeout
	assert(absf(door.rotation.y - deg_to_rad(-100)) < 0.001, "Door did not open")
	focus = Vector3(-0.35, 0.8, -0.65)
	distance = 4.4
	update_camera()
	await screenshot("res://artifacts/refuge_02/atelier.png")
	focus = Vector3(1.4, 0.8, 0)
	distance = 10.5
	update_camera()
	toggle_lighting()
	await screenshot("res://artifacts/refuge_02/ambiance.png")
	print("REFUGE_REVIEW_CAPTURE_OK: assembly, animation and door travel")
	get_tree().quit()
