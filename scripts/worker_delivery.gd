class_name WorkerDelivery
extends RefCounted
## Gameplay worker controller driven only by simulation time, including animations.
const GROUND_Y := -0.0105
const CAPTURE_TIME := 0.72
const DEPOSIT_TIME := 1.08
var game: Node3D
var worker: Dictionary
var actor: ResidentAnimator
var ledger: DeliveryLedger
var owner: int
var job := -1
var state := "idle"
var timer := 0.0
var anim_time := 0.0
var source_position := Vector3.ZERO
var destination_position := Vector3.ZERO
var cargo_socket: Node3D
var contact: Transform3D
var deposited := false
var completed_deliveries := 0

func setup(world: Node3D, data: Dictionary, index: int, transactions: DeliveryLedger) -> void:
	game = world
	worker = data
	owner = index
	ledger = transactions
	actor = worker.node
	actor.manage_cargo_visibility = false
	actor.player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	cargo_socket = actor.cargo.get_parent()
	pose("pick_up", CAPTURE_TIME)
	contact = actor.global_transform.affine_inverse() * actor.cargo.global_transform
	actor.cargo.hide()
	pose("idle", 0)
	destination_position = game.HOME + Vector3(1.6, GROUND_Y, 0.25)

func pose(clip: String, time: float) -> void:
	if actor.current != clip: actor.set_action(clip, 0.0)
	actor.player.seek(time, true)
	actor.player.advance(0)
	actor.skeleton.force_update_all_bone_transforms()
	cargo_socket.transform = actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("socket_carry"))

func change(next: String) -> void:
	state = next
	timer = 0.0
	anim_time = 0.0

func cancel() -> void:
	if state == "putdown": return # Complete an unloading already in progress.
	if job < 0: return
	if ledger.cancel(job):
		job = -1
		actor.cargo.hide()
		worker.work = 0.0
		change("return_home")
	else:
		ledger.leave_source(job)
		change("waiting_storage")

func update(dt: float) -> void:
	# Bound event steps so accelerated simulation cannot skip grasp/release.
	var remaining := dt
	while remaining > 0.000001:
		var step := minf(remaining, 0.05)
		tick(step)
		remaining -= step

func move(target: Vector3, dt: float, loaded: bool) -> bool:
	var delta := target - actor.position
	delta.y = 0
	var distance := delta.length()
	if distance < 0.001:
		actor.position = target
		return true
	var velocity: float = 1.7 + game.workshops * 0.35
	var travel := minf(distance, dt * velocity)
	actor.rotation.y = atan2(delta.x, delta.z)
	actor.position += delta.normalized() * travel
	actor.position.y = GROUND_Y
	var clip := "carry_walk" if loaded else "walk"
	anim_time += travel / float(ResidentAnimator.SPEEDS[clip])
	pose(clip, fposmod(anim_time, actor.player.get_animation(clip).length))
	return distance - travel < 0.001

func tick(dt: float) -> void:
	timer += dt
	match state:
		"idle":
			pose("idle", fposmod(timer, 4.0))
			if game.hiding or worker.patch < 0: return
			job = ledger.reserve(owner, worker.patch, 3 + game.workshops)
			if job < 0: return
			worker.kind = ledger.jobs[job].kind
			source_position = game.patches[worker.patch].pos + Vector3(0.9, GROUND_Y, 0.2)
			actor.cargo.reparent(game, true)
			actor.cargo.global_transform = Transform3D(Basis.IDENTITY, source_position) * contact
			actor.cargo.show()
			deposited = false
			change("to_source")
		"to_source":
			if move(source_position, dt, false):
				actor.rotation.y = 0
				change("gather")
		"gather":
			pose("idle", fposmod(timer, 4.0))
			worker.work = timer
			if timer >= 2.0:
				worker.work = 0.0
				change("pickup")
		"pickup":
			pose("pick_up", minf(timer, 1.8))
			if timer >= CAPTURE_TIME and worker.carrying == 0:
				worker.carrying = ledger.collect(job)
				actor.cargo.reparent(cargo_socket, false)
				actor.cargo.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.52), Vector3.ZERO)
			if timer >= 1.8:
				ledger.leave_source(job)
				change("waiting_storage")
		"waiting_storage":
			if ledger.acquire_destination(job):
				change("to_storage")
			else:
				var queue: Vector3 = game.HOME + Vector3(0.4 + owner % 3 * 0.5, GROUND_Y, 1.4 + owner / 3 * 0.5)
				if move(queue, dt, true): pose("pick_up", 1.8)
		"to_storage":
			if move(destination_position, dt, true):
				actor.rotation.y = 0
				change("putdown")
		"putdown":
			pose("put_down", minf(timer, 1.8))
			if timer >= DEPOSIT_TIME and not deposited:
				actor.cargo.reparent(game, true)
				actor.cargo.global_transform = Transform3D(Basis.IDENTITY, destination_position) * contact
				var amount := ledger.deliver(job, game.stock)
				assert(amount == worker.carrying and amount > 0)
				worker.carrying = 0
				deposited = true
				completed_deliveries += 1
			if timer >= 1.8:
				ledger.release_destination(job)
				job = -1
				actor.cargo.hide()
				change("idle" if worker.patch >= 0 and not game.hiding else "return_home")
		"return_home":
			if move(game.HOME + Vector3(0, GROUND_Y, 0), dt, false): change("idle")

func description() -> String:
	return {"idle": "Disponible", "to_source": "Vers la caisse", "gather": "Prépare la charge", "pickup": "Prend la caisse", "waiting_storage": "Attend le dépôt", "to_storage": "Rapporte la caisse", "putdown": "Dépose", "return_home": "Rentre au refuge"}.get(state, state)
