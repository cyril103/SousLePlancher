extends "res://scripts/animation_review.gd"
## Deterministic review timeline; no colony navigation or task scheduling yet.
var mode := 0
var clock_time := 0.0
var socket: Node3D
var supports: Array[Node3D] = []
var landing: Node3D
var source_transform: Transform3D
var destination_transform: Transform3D
var carrying := false
var deposited := false
var status := ""
const WALK_TIME := 1.8 / 0.36796537
const END_CARRY := 1.8 + 0.6 + WALK_TIME + 0.6 + 1.8
const END_CLIMB := 1.2 + 4.8 + 1.4
const LANDING_HEIGHT := 2.04
# Boot sole: center 0.032 minus half its thickness 0.043 (Blender source).
const SOLE_REST_HEIGHT := 0.0105

func _ready() -> void:
	super._ready()
	for x in [-2.0, 2.0]:
		for z in [-2.0, 0.0, 2.0]:
			asset("reference_01/floor_module_2x2", Vector3(x, -0.055, z))
	actor.manage_cargo_visibility = false
	actor.player.speed_scale = 0
	socket = actor.cargo.get_parent()
	actor.position = Vector3(-0.9, 0, 0)
	actor.rotation.y = 0
	sample("pick_up", 0.72)
	actor.skeleton.force_update_all_bone_transforms()
	socket.transform = actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("socket_carry"))
	source_transform = actor.cargo.global_transform
	destination_transform = source_transform
	destination_transform.origin.x += 1.8
	for transform in [source_transform, destination_transform]:
		var support := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.6, transform.origin.y, 0.48)
		support.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color("5c5140")
		support.material_override = mat
		add_child(support)
		support.position = transform.origin - Vector3(0, transform.origin.y / 2.0, 0)
		supports.append(support)
	# The wooden board surface is at local Y=0, not +0.055.
	landing = asset("reference_01/floor_module_2x2", Vector3(0, LANDING_HEIGHT, -1.05))
	restart(0)
	if "--review-ladder" in OS.get_cmdline_user_args():
		restart(1)
	if "--capture-interactions" in OS.get_cmdline_user_args():
		verify.call_deferred()

func sample(clip: String, time: float) -> void:
	if actor.current != clip:
		actor.set_action(clip, 0.0)
	actor.player.seek(time, true)
	actor.player.advance(0)
	actor.skeleton.force_update_all_bone_transforms()
	if is_instance_valid(socket):
		socket.transform = actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("socket_carry"))

func restart(new_mode: int) -> void:
	mode = new_mode
	clock_time = 0
	carrying = false
	deposited = false
	paused = false
	actor.cargo.reparent(self, true)
	actor.cargo.global_transform = source_transform
	actor.cargo.visible = mode == 0
	bench.hide()
	ladder.visible = mode == 1
	landing.visible = mode == 1
	for support in supports: support.visible = mode == 0
	yaw = 0.8
	distance = 4.4
	evaluate()

func evaluate() -> void:
	var t := clock_time
	if mode == 0:
		actor.position = Vector3(-0.9, 0, 0)
		actor.rotation.y = 0
		if t < 1.8:
			status = "Saisir la caisse"
			sample("pick_up", t)
		elif t < 2.4:
			status = "Se tourner vers la destination"
			actor.rotation.y = smoothstep(1.8, 2.4, t) * PI / 2
			sample("pick_up", 1.8)
		elif t < 2.4 + WALK_TIME:
			status = "Transporter"
			actor.rotation.y = PI / 2
			actor.position.x += (t - 2.4) * 0.36796537
			sample("carry_walk", fposmod(t - 2.4, 1.4))
		elif t < 3.0 + WALK_TIME:
			status = "Se placer devant le dépôt"
			actor.position.x = 0.9
			actor.rotation.y = (1.0 - smoothstep(2.4 + WALK_TIME, 3.0 + WALK_TIME, t)) * PI / 2
			sample("put_down", 0)
		else:
			status = "Déposer" if t < END_CARRY else "Livraison terminée"
			actor.position.x = 0.9
			sample("put_down", minf(t - 3.0 - WALK_TIME, 1.8))
		if t >= 0.72 and not carrying and not deposited:
			actor.cargo.reparent(socket, true)
			actor.cargo.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.52), Vector3.ZERO)
			carrying = true
		if t >= 3.0 + WALK_TIME + 1.08 and not deposited:
			actor.cargo.reparent(self, true)
			actor.cargo.global_transform = destination_transform
			deposited = true
			carrying = false
	else:
		actor.rotation.y = PI
		actor.position = Vector3(0, 0, 0.36)
		if t < 1.2:
			status = "Prendre appui sur l'échelle"
			sample("climb_enter", t)
		elif t < 6.0:
			status = "Monter"
			var height := (t - 1.2) * 0.31875
			actor.position = Vector3(0, height, 0.36 - 0.19 * height)
			sample("climb", fposmod(t - 1.2, 1.6))
		else:
			status = "Rejoindre le palier" if t < END_CLIMB else "Palier atteint"
			actor.position = Vector3(0, 1.53, 0.36 - 0.19 * 1.53)
			# Settle onto the board continuously; the rig origin sits slightly
			# below the actual sole geometry in the authored standing pose.
			actor.position.y -= SOLE_REST_HEIGHT * smoothstep(6.0, END_CLIMB, t)
			sample("climb_exit", minf(t - 6.0, 1.4))
	actor.player.speed_scale = 0
	label.text = "%s%s · ×%.2f\n1 Livraison   2 Échelle   R Recommencer   Espace Pause   −/+ Vitesse\nGlisser : tourner   Molette : zoom   F11 : plein écran   Échap : fermer" % [status, " · PAUSE" if paused else "", rate]
	update_camera()

func _process(delta: float) -> void:
	if not is_instance_valid(socket): return
	if not paused:
		clock_time = minf(clock_time + delta * rate, END_CARRY if mode == 0 else END_CLIMB)
	evaluate()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: restart(0); return
			KEY_2: restart(1); return
			KEY_R: restart(mode); return
			KEY_3, KEY_4, KEY_5, KEY_D: return
	super._unhandled_input(event)

func sole_world_position(side: String) -> Vector3:
	var bone := actor.skeleton.find_bone(side + "_foot")
	var ankle := actor.skeleton.get_bone_global_pose(bone).origin
	# This contact probe applies to the final level-foot pose. The ankle is
	# authored at 0.13 and the underside of the sole at 0.0105 in that pose.
	return actor.skeleton.global_transform * (ankle - Vector3(0, 0.13 - SOLE_REST_HEIGHT, 0))

func verify() -> void:
	DirAccess.make_dir_recursive_absolute("res://artifacts/interactions_04")
	var identity := actor.cargo.get_instance_id()
	for m in [0, 1]:
		restart(m)
		paused = true
		for t in ([0.0, 0.72, 1.8, 4.0, END_CARRY] if m == 0 else [0.0, 1.2, 3.6, END_CLIMB]):
			clock_time = t
			evaluate()
			assert(actor.cargo.get_instance_id() == identity)
			if m == 0 and t == END_CARRY:
				assert(deposited and actor.cargo.get_parent() == self)
				assert(actor.cargo.global_position.distance_to(destination_transform.origin) < 0.001)
			if m == 1 and t == END_CLIMB:
				for side in ["L", "R"]:
					var sole := landing.to_local(sole_world_position(side))
					print("LANDING_SOLE ", side, " clearance=", sole.y)
					assert(absf(sole.y) < 0.002, "Sole must touch the wooden landing: " + side)
					assert(absf(sole.x) < 0.98 and absf(sole.z) < 0.98, "Sole must be above the landing")
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://artifacts/interactions_04/%d_%.2f.png" % [m, t])
	print("INTERACTION_REVIEW_OK: same cargo instance, delivery completed, 9 captures")
	get_tree().quit()
