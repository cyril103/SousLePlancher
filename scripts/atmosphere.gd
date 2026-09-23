extends Node3D
## Lightweight atmosphere for Compatibility: mesh shafts and CPU particles.
const WEATHER = preload("res://shaders/weathered.gdshader")
const SHAFT = preload("res://shaders/light_shaft.gdshader")
const FLAME = preload("res://shaders/flame.gdshader")
const DUST = preload("res://shaders/dust.gdshader")
const COBWEB = preload("res://shaders/cobweb.gdshader")
var torches: Array[OmniLight3D] = []
var daylight: Array[SpotLight3D] = []
var clock := 0.0
static var materials: Dictionary = {}

static func cached_material(key: String, shader: Shader) -> ShaderMaterial:
	# Share materials and retain their RIDs while deferred scene teardown completes.
	if not materials.has(key):
		var material := ShaderMaterial.new()
		material.shader = shader
		materials[key] = material
	return materials[key]

static func age_materials(node: Node) -> void:
	# Skip purely visual work in simulation tests; graphical runs verify the shaders.
	if DisplayServer.get_name() == "headless": return
	if node is MeshInstance3D:
		for surface in range(node.mesh.get_surface_count()):
			var source := node.mesh.surface_get_material(surface) as StandardMaterial3D
			if source == null: continue
			if "soie" in source.resource_name.to_lower():
				node.set_surface_override_material(surface, cached_material("cobweb", COBWEB))
				node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				continue
			var key := source.resource_name + source.albedo_color.to_html() + str("Lame" in str(node.name))
			var mat := cached_material(key, WEATHER)
			mat.set_shader_parameter("base_color", source.albedo_color)
			var material_name := source.resource_name.to_lower()
			var timber := "bois" in material_name or "chêne" in material_name
			mat.set_shader_parameter("timber", timber)
			mat.set_shader_parameter("wear", 0.90 if timber else 0.35)
			mat.set_shader_parameter("floor_surface", "Lame" in str(node.name))
			node.set_surface_override_material(surface, mat)
	for child in node.get_children(): age_materials(child)

func _ready() -> void:
	name = "Atmosphere"
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("080d10")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("74858b")
	env.environment.ambient_light_energy = 0.38
	add_child(env)
	# Very weak bounced light keeps unlit resources readable without daylight everywhere.
	var bounce := DirectionalLight3D.new()
	bounce.rotation_degrees = Vector3(-65, -35, 0)
	bounce.light_color = Color("7e929b")
	bounce.light_energy = 0.12
	add_child(bounce)
	var scenery := load("res://assets/models/underfloor.glb").instantiate() as Node3D
	add_child(scenery)
	age_materials(scenery)
	add_daylight(Vector3(-7.0, 4.18, -5.85), Vector3(-4.3, -0.35, -1.25), 1.28, 2.65, 3.0, 0.65)
	add_daylight(Vector3(-0.7, 4.24, -5.95), Vector3(1.45, -0.2, -2.35), 0.64, 1.85, 19.0, 0.42)
	add_daylight(Vector3(6.4, 4.19, -5.90), Vector3(8.25, -0.4, -2.65), 1.65, 2.15, 41.0, 0.86)
	add_torch(Vector3(-6.3, 0, 3.8))
	add_torch(Vector3(3.0, 0, 4.9))
	add_dust(Vector3(0, 1.5, 0), Vector3(10.8, 1.4, 6.5), 220, false)

func add_daylight(top: Vector3, bottom: Vector3, width: float, energy: float, seed: float, flatten: float) -> void:
	var light := SpotLight3D.new()
	add_child(light)
	light.position = top
	light.look_at(bottom)
	light.light_color = Color("d8dfd2").lerp(Color("dfcfa9"), seed * 0.013)
	light.light_energy = energy
	light.set_meta("base_energy", energy)
	light.spot_range = top.distance_to(bottom) + 4.0
	light.spot_angle = 16.0 + width * 9.0
	light.spot_attenuation = 0.65
	light.spot_angle_attenuation = 2.5
	light.shadow_enabled = true
	light.shadow_bias = 0.05
	daylight.append(light)
	var margin := Vector3(width * 2.4, 0.5, width * 2.4)
	var low := top.min(bottom) - margin
	var high := top.max(bottom) + margin
	var volume := MeshInstance3D.new()
	volume.name = "DaylightVolume%d" % daylight.size()
	var box := BoxMesh.new()
	box.size = high - low
	volume.mesh = box
	volume.position = (low + high) * 0.5
	var mat := cached_material("volume_%s" % seed, SHAFT)
	mat.set_shader_parameter("beam_start", top)
	mat.set_shader_parameter("beam_end", bottom)
	mat.set_shader_parameter("bounds_min", low)
	mat.set_shader_parameter("bounds_max", high)
	mat.set_shader_parameter("width", width)
	mat.set_shader_parameter("seed", seed)
	mat.set_shader_parameter("flatten", flatten)
	mat.set_shader_parameter("strength", 0.38 / sqrt(width))
	mat.set_shader_parameter("tint", light.light_color)
	volume.material_override = mat
	volume.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(volume)
	light.set_meta("volume_material", mat)
	# Dust is distributed along the actual shaft, not in three identical columns.
	for i in range(3):
		var fraction := 0.20 + i * 0.25
		var pos := top.lerp(bottom, fraction)
		add_dust(pos, Vector3(width * (0.3 + fraction), 0.6, width * 0.5), 18 + i * 6, true)

func add_torch(pos: Vector3) -> void:
	if DisplayServer.get_name() == "headless": return
	var torch := load("res://assets/models/torch.glb").instantiate() as Node3D
	add_child(torch)
	torch.position = pos
	age_materials(torch)
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, 1.35, 0)
	light.light_color = Color("ffb459")
	light.light_energy = 2.2
	light.omni_range = 5.5
	light.omni_attenuation = 1.1
	light.shadow_enabled = true
	add_child(light)
	torches.append(light)
	var flame := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.10
	mesh.height = 0.40
	mesh.radial_segments = 12
	mesh.rings = 6
	flame.mesh = mesh
	flame.position = pos + Vector3(0, 1.22, 0)
	var material := cached_material("flame_%s" % pos.x, FLAME)
	material.set_shader_parameter("seed", pos.x)
	flame.material_override = material
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flame)
	# A few embers above the flame, fading quickly instead of a thick smoke column.
	add_dust(pos + Vector3(0, 1.48, 0), Vector3(0.12, 0.12, 0.12), 8, true, true)

func add_dust(pos: Vector3, extents: Vector3, amount: int, bright: bool, embers: bool = false) -> void:
	var particles := CPUParticles3D.new()
	particles.position = pos
	particles.amount = amount
	particles.lifetime = 3.0 if embers else 18.0
	particles.preprocess = particles.lifetime
	particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	particles.emission_box_extents = extents
	particles.gravity = Vector3(0, 0.03 if embers else -0.003, 0)
	particles.direction = Vector3(0.25, 1 if embers else 0.10, 0.14)
	particles.spread = 45
	particles.initial_velocity_min = 0.09
	particles.initial_velocity_max = 0.18
	particles.scale_amount_min = 0.55
	particles.scale_amount_max = 1.0
	var mesh := QuadMesh.new()
	var diameter := 0.045 if embers else (0.10 if bright else 0.07)
	mesh.size = Vector2.ONE * diameter
	particles.mesh = mesh
	var mat := cached_material("dust", DUST)
	particles.material_override = mat
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0,0.15,0.7,1.0])
	var tint := Color(1,0.43,0.12,0.5) if embers else Color(0.95,0.98,0.90,0.9 if bright else 0.38)
	ramp.colors = PackedColorArray([Color(tint,0),tint,tint,Color(tint,0)])
	particles.color_ramp = ramp
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)

func _process(delta: float) -> void:
	clock += delta
	for i in range(torches.size()):
		torches[i].light_energy = 2.2 + sin(clock*8.0+i*2)*0.16 + sin(clock*13.7+i)*0.10
	# Passing humans briefly interrupt daylight through the cracks.
	var phase := fmod(float(get_parent().get("elapsed")),100.0)
	var occlusion := 1.0
	if phase >= 68.0 and phase < 88.0: occlusion = 0.5 + 0.5*absf(sin((phase-68)*0.65))
	for light in daylight:
		light.light_energy = float(light.get_meta("base_energy")) * occlusion
		(light.get_meta("volume_material") as ShaderMaterial).set_shader_parameter("daylight", occlusion)


