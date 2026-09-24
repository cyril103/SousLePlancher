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
var route := PackedVector3Array()
var route_index := 0
var route_revision := -1
var route_target := Vector3.INF
var navigation_issue := ""
var retry_time := 0.0
var depot_revision := -1
var depot_accessible := true
var climbing := false
var climb_up := false
var climb_time := 0.0
var cancel_after_ladder := false
var ladder_exit := Vector3.INF
var waiting_ladder := false
var crossings := 0

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
	route.clear()
	route_index = 0
	route_revision = -1
	retry_time = 0.0

func cancel() -> void:
	if climbing:
		cancel_after_ladder = true
		return
	game.ladder.release(owner)
	waiting_ladder = false
	navigation_issue = ""
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
	if not plan_route(target):
		pose("pick_up" if loaded else "idle", 1.8 if loaded else fposmod(timer, 4.0))
		return false
	var velocity: float = 1.7 + game.workshops * 0.35
	var budget := dt * velocity
	var travel := 0.0
	while budget > 0 and route_index < route.size():
		var target_point := route[route_index]
		if absf(target_point.y - actor.position.y) > 1:
			climbing = true
			climb_up = target_point.y > actor.position.y
			climb_time = 0
			if loaded: actor.cargo.reparent(game, true)
			advance_ladder(0)
			return false
		if route_index + 1 < route.size() and absf(route[route_index + 1].y - target_point.y) > 1:
			waiting_ladder = not game.ladder.request(owner)
			if waiting_ladder:
				pose("pick_up" if loaded else "idle", 1.8 if loaded else 0.0)
				return false
		var delta := route[route_index] - actor.position
		delta.y = 0
		var distance := delta.length()
		if distance < 0.001:
			route_index += 1
			continue
		var step := minf(distance, budget)
		actor.rotation.y = rotate_toward(actor.rotation.y, atan2(delta.x, delta.z), dt * 9.0)
		actor.position += delta.normalized() * step
		actor.position.y = target_point.y
		travel += step
		budget -= step
		if step >= distance - 0.001: route_index += 1
	var clip := "carry_walk" if loaded else "walk"
	anim_time += travel / float(ResidentAnimator.SPEEDS[clip])
	pose(clip, fposmod(anim_time, actor.player.get_animation(clip).length))
	return route_index >= route.size()

func plan_route(target: Vector3) -> bool:
	if route_revision == game.travel_revision() and route_target.is_equal_approx(target):
		if not route.is_empty(): return true
		if retry_time > 0: return false
	route_target = target
	route_revision = game.travel_revision()
	route = game.travel_path(actor.position, target, owner)
	route_index = 0
	retry_time = 1.0
	if route.is_empty():
		game.ladder.release(owner)
		waiting_ladder = false
		navigation_issue = "Trajet bloqué vers " + ("le dépôt" if worker.carrying > 0 else ("le refuge" if state == "return_home" else "le gisement"))
		return false
	navigation_issue = ""
	return true

func at_refuge() -> bool:
	return actor.position.distance_to(game.home_position(owner)) < 0.12

func depot_reachable() -> bool:
	if depot_revision != game.travel_revision():
		depot_revision = game.travel_revision()
		depot_accessible = not game.travel_path(actor.position, destination_position, owner).is_empty()
	return depot_accessible

func tick(dt: float) -> void:
	if climbing:
		advance_ladder(dt)
		return
	if game.ladder.owner == owner and ladder_exit != Vector3.INF and actor.position.distance_to(ladder_exit) > .65:
		game.ladder.release(owner)
		ladder_exit = Vector3.INF
	timer += dt
	retry_time = maxf(0, retry_time - dt)
	match state:
		"idle":
			pose("idle", fposmod(timer, 4.0))
			if game.hiding or worker.patch < 0: return
			source_position = game.patches[worker.patch].pos + Vector3(0.9, GROUND_Y, 0.2)
			if not plan_route(source_position): return
			job = ledger.reserve(owner, worker.patch, 3 + game.workshops)
			if job < 0: return
			worker.kind = ledger.jobs[job].kind
			actor.cargo.reparent(game, true)
			actor.cargo.global_transform = Transform3D(Basis.IDENTITY, source_position) * contact
			actor.cargo.show()
			deposited = false
			change("to_source")
		"to_source":
			if move(source_position, dt, false):
				actor.rotation.y = 0
				change("gather")
			elif not navigation_issue.is_empty():
				# No charge has been taken: release the source immediately.
				ledger.cancel(job)
				job = -1
				actor.cargo.hide()
				change("idle")
				retry_time = 1.0
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
			# Descend before joining the depot queue: a waiting climber must not lock it.
			if actor.position.y > 1:
				move(game.ladder.waiting(owner, false), dt, true)
				return
			if depot_reachable() and ledger.acquire_destination(job):
				change("to_storage")
			else:
				if not depot_reachable(): ledger.release_destination(job)
				if move(game.queue_position(owner), dt, true): pose("pick_up", 1.8)
				if not depot_reachable(): navigation_issue = "Trajet bloqué vers le dépôt"
		"to_storage":
			if move(destination_position, dt, true):
				actor.rotation.y = 0
				change("putdown")
			elif not navigation_issue.is_empty():
				ledger.release_destination(job)
				change("waiting_storage")
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
			if move(game.home_position(owner), dt, false): change("idle")

func description() -> String:
	if climbing: return "Monte l’échelle" if climb_up else "Descend l’échelle"
	if waiting_ladder: return "Attend le passage de l’échelle"
	if not navigation_issue.is_empty(): return navigation_issue
	if state == "idle":
		if game.hiding and at_refuge(): return "À l’abri"
		if worker.patch >= 0: return "Gisement épuisé" if game.patches[worker.patch].amount <= 0 else "Attend le poste de récolte"
	return {"idle": "Disponible", "to_source": "Vers la caisse", "gather": "Prépare la charge", "pickup": "Prend la caisse", "waiting_storage": "Attend le dépôt", "to_storage": "Rapporte la caisse", "putdown": "Dépose", "return_home": "Rentre au refuge"}.get(state, state)

func advance_ladder(dt: float) -> void:
	climb_time += dt
	var sample: Dictionary = game.ladder.sample(actor, climb_time, climb_up)
	pose(sample.clip, sample.time)
	if worker.carrying > 0:
		var root_bone := actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone("root"))
		actor.cargo.global_transform = actor.global_transform * Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * .52), root_bone.origin + Vector3(0, .98, -.43))
	if climb_time < (7.4 if climb_up else 8.0): return
	climbing = false
	crossings += 1
	# Bake the exit clip's root translation before returning to an in-place walk.
	actor.position = game.Ladder.UPPER if climb_up else game.Ladder.LOWER
	ladder_exit = actor.position
	route_index += 1
	pose("pick_up" if worker.carrying > 0 else "idle", 1.8 if worker.carrying > 0 else 0.0)
	if worker.carrying > 0:
		actor.cargo.reparent(cargo_socket, false)
		actor.cargo.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * .52), Vector3.ZERO)
	if cancel_after_ladder:
		cancel_after_ladder = false
		cancel()
