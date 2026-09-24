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
var inside_refuge := false
var door_active := false
var door_entering := false
var door_route := PackedVector3Array()
var door_index := 0
var waiting_door := false
var exit_requested := false
var recall_after_door := false
var door_crossings := 0
var bridge_active := false
var bridge_target := Vector3.ZERO
var bridge_cancel := false
var waiting_bridge := false
var bridge_crossings := 0
var exploring := false
var exploration_time := 0.0
var rest_bed := -1
var furniture_order := -1
var supply_job := -1
var depot_id := 0
var need_depot := -1
var need_kind := ""
var rest_recall := false
var personal_recall := false
var needs_supply := -1
var need_interrupt := false
var consumption_time := 0.0

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
	if game.torches.held(owner) >= 0 and clip in ["idle", "walk"]: clip = "torch_" + clip
	if actor.current != clip: actor.set_action(clip, 0.0)
	actor.player.seek(time, true)
	actor.player.advance(0)
	actor.skeleton.force_update_all_bone_transforms()
	# Manual animation sampling must also refresh props while the game is paused.
	for socket in actor.skeleton.get_children():
		if socket is BoneAttachment3D:
			socket.transform = actor.skeleton.get_bone_global_pose(actor.skeleton.find_bone(socket.bone_name))

func change(next: String) -> void:
	state = next
	timer = 0.0
	anim_time = 0.0
	route.clear()
	route_index = 0
	route_revision = -1
	retry_time = 0.0

func cancel() -> void:
	if game.torches.recall(self):
		if door_active: recall_after_door = true
		return
	# A ration already withdrawn is consumed once; recall cannot duplicate or discard it.
	if game.needs.consuming(self): return
	needs_supply = -1
	exploring = false
	exploration_time = 0
	if bridge_active:
		bridge_cancel = true
		return
	game.bridge.release(owner)
	waiting_bridge = false
	if state == "explore" and not climbing: change("return_home")
	exit_requested = false
	if door_active:
		recall_after_door = true
		return
	game.refuge.release(owner)
	waiting_door = false
	if inside_refuge:
		if state == "floor_sleep":
			actor.position = game.refuge.slot(owner)
			actor.rotation.y = 0
			pose("idle", 0)
		change("idle")
		return
	if climbing:
		cancel_after_ladder = true
		return
	game.ladder.release(owner)
	waiting_ladder = false
	navigation_issue = ""
	game.needs.interrupt(self)
	if game.construction.cancel(self): return
	if game.sleeping.interrupt(self): return
	if state == "putdown": return # Complete an unloading already in progress.
	if job < 0: return
	if ledger.cancel(job):
		game.depots.release("h:%d" % job)
		game.depots.gate(depot_id).release_destination(job)
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
	var velocity: float = (1.7 + game.workshops * 0.35) * game.needs.movement_factor(worker)
	var budget := dt * velocity
	var travel := 0.0
	while budget > 0 and route_index < route.size():
		var target_point := route[route_index]
		if game.bridge.is_edge(actor.position, target_point):
			bridge_active = true
			bridge_target = target_point
			return false
		if route_index + 1 < route.size() and game.bridge.is_edge(target_point, route[route_index + 1]):
			waiting_bridge = not game.bridge.request(owner)
			if waiting_bridge:
				pose("pick_up" if loaded else "idle", 1.8 if loaded else 0.0)
				return false
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
	if game.torches.held(owner) >= 0 and is_inf(game.torches.route_length(actor.position, target, owner)):
		route.clear()
	route_index = 0
	retry_time = 1.0
	if route.is_empty():
		game.bridge.release(owner)
		waiting_bridge = false
		game.ladder.release(owner)
		waiting_ladder = false
		navigation_issue = "Trajet bloqué vers " + ("le dépôt" if worker.carrying > 0 else ("le refuge" if state == "return_home" else "le gisement"))
		if state == "explore": navigation_issue = "Trajet bloqué vers la réserve de l’Est"
		return false
	navigation_issue = ""
	return true

func at_refuge() -> bool:
	return inside_refuge

func depot_reachable() -> bool:
	if depot_revision != game.travel_revision():
		depot_revision = game.travel_revision()
		depot_accessible = not game.travel_path(actor.position, destination_position, owner).is_empty()
	return depot_accessible

func set_depot(id: int) -> void:
	if depot_id == id and destination_position == game.depots.entry(id): return
	depot_id = id
	destination_position = game.depots.entry(id)
	depot_revision = -1

func harvest_destination() -> bool:
	if depot_reachable(): return true
	var token := "h:%d" % job
	var previous := depot_id
	if not game.depots.reroute(token, actor.position, owner): return false
	set_depot(game.depots.incoming[token].id)
	if previous != depot_id: game.depots.gate(previous).release_destination(job)
	return true

func tick(dt: float) -> void:
	game.torches.advance(self, dt)
	game.sleeping.update_need(self, dt)
	game.needs.update(self, dt)
	if bridge_active:
		advance_bridge(dt)
		return
	if door_active:
		advance_door(dt)
		return
	if climbing:
		advance_ladder(dt)
		return
	if game.ladder.owner == owner and ladder_exit != Vector3.INF and actor.position.distance_to(ladder_exit) > .65:
		game.ladder.release(owner)
		ladder_exit = Vector3.INF
	timer += dt
	retry_time = maxf(0, retry_time - dt)
	if game.torches.tick(self, dt): return
	if game.construction.tick(self, dt): return
	if game.torches.held(owner) < 0 and game.needs.tick(self, dt): return
	if game.torches.start_work(self): return
	if game.torches.held(owner) < 0 and needs_supply < 0 and not (need_interrupt and state == "return_home"):
		if game.sleeping.tick(self, dt): return
	match state:
		"idle":
			pose("idle", fposmod(timer, 4.0))
			if inside_refuge:
				actor.rotation.y = rotate_toward(actor.rotation.y, 0, dt * 2)
				if not game.hiding and (exit_requested or worker.patch >= 0 or exploring or needs_supply >= 0): change("leave_home")
				return
			if exploring and not game.hiding:
				change("explore")
				return
			var patch: int = needs_supply if needs_supply >= 0 else worker.patch
			if game.hiding or patch < 0: return
			source_position = game.patches[patch].pos + Vector3(0.9, GROUND_Y, 0.2)
			if not plan_route(source_position): return
			var choice: Dictionary = game.depots.sink(source_position, game.patches[patch].kind, mini(3 + game.workshops, game.patches[patch].amount - game.patches[patch].reserved), owner)
			if choice.is_empty():
				navigation_issue = "Aucun dépôt accessible n’accepte cette charge ou n’a de place"
				return
			job = ledger.reserve(owner, patch, choice.quantity)
			if job < 0: return
			game.depots.reserve_in("h:%d" % job, choice)
			set_depot(choice.id)
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
				game.depots.release("h:%d" % job)
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
			if harvest_destination() and game.depots.gate(depot_id).acquire_slot(job):
				change("to_storage")
			else:
				if not depot_reachable(): game.depots.gate(depot_id).release_destination(job)
				if move(game.depots.waiting(depot_id, owner), dt, true): pose("pick_up", 1.8)
				if not depot_reachable(): navigation_issue = "Trajet bloqué vers le dépôt"
		"to_storage":
			if move(destination_position, dt, true):
				actor.rotation.y = 0
				change("putdown")
			elif not navigation_issue.is_empty():
				game.depots.gate(depot_id).release_destination(job)
				change("waiting_storage")
		"putdown":
			pose("put_down", minf(timer, 1.8))
			if timer >= DEPOSIT_TIME and not deposited:
				actor.cargo.reparent(game, true)
				actor.cargo.global_transform = Transform3D(Basis.IDENTITY, destination_position) * contact
				var amount := ledger.deliver(job, game.depots.stocks(depot_id), game.depots.gate(depot_id).destination_owner == job)
				game.depots.release("h:%d" % job)
				assert(amount == worker.carrying and amount > 0)
				worker.carrying = 0
				deposited = true
				completed_deliveries += 1
			if timer >= 1.8:
				game.depots.gate(depot_id).release_destination(job)
				job = -1
				set_depot(0)
				actor.cargo.hide()
				change("idle" if worker.patch >= 0 and not game.hiding else "return_home")
		"return_home":
			if inside_refuge:
				change("idle")
				return
			if game.refuge.passage_owner != owner:
				if not move(game.home_position(owner), dt, false): return
				waiting_door = not game.refuge.request(owner)
				if waiting_door:
					pose("idle", 0)
					return
			if game.refuge.opening < 1:
				pose("idle", 0)
				return
			if move(game.HOME + game.Refuge.OUTSIDE, dt, false):
				begin_door(true)
			elif not navigation_issue.is_empty(): game.refuge.release(owner)
		"leave_home":
			waiting_door = not game.refuge.request(owner)
			pose("idle", 0)
			if not waiting_door and game.refuge.opening >= 1: begin_door(false)
		"explore":
			if move(game.Bridge.SCOUT_POINT, dt, false):
				pose("idle", fposmod(timer, 4))
				exploration_time += dt
				if exploration_time >= 3:
					game.discover_east()
					exploring = false
					change("return_home")

func description() -> String:
	var torch_description: String = game.torches.description(self)
	if not torch_description.is_empty(): return torch_description
	var supply_description: String = game.construction.description(self)
	if not supply_description.is_empty() and not climbing and not bridge_active and not door_active: return supply_description
	var vital_description: String = game.needs.description(self)
	if not vital_description.is_empty() and not climbing and not bridge_active and not door_active: return vital_description
	var need_description: String = game.sleeping.description(self)
	if not need_description.is_empty() and not climbing and not bridge_active and not door_active: return need_description
	if bridge_active: return "Traverse la passerelle"
	if waiting_bridge: return "Attend la passerelle"
	if exploring and not climbing and not door_active: return navigation_issue if not navigation_issue.is_empty() else "Reconnaît la réserve de l’Est"
	if door_active: return "Entre dans le refuge" if door_entering else "Franchit la porte vers l’extérieur"
	if waiting_door: return "Attend la porte du refuge"
	if inside_refuge: return "À l’abri" if state == "idle" else "Se prépare à sortir"
	if climbing: return "Monte l’échelle" if climb_up else "Descend l’échelle"
	if waiting_ladder: return "Attend le passage de l’échelle"
	if not navigation_issue.is_empty(): return navigation_issue
	if state == "idle":
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

func resume_from_refuge() -> void:
	exit_requested = true
	recall_after_door = false
	if state == "return_home" and not door_active and not inside_refuge and not climbing:
		game.refuge.release(owner)
		waiting_door = false
		change("idle")

func begin_door(entering: bool) -> void:
	door_entering = entering
	door_active = true
	waiting_door = false
	door_index = 0
	var slot: Vector3 = game.refuge.slot(owner)
	var aisle := Vector3(game.HOME.x, GROUND_Y, slot.z)
	var inner: Vector3 = game.HOME + game.Refuge.INSIDE
	var outer: Vector3 = game.HOME + game.Refuge.OUTSIDE
	if entering:
		door_route = PackedVector3Array([inner, aisle, slot])
	else:
		door_route = PackedVector3Array([aisle, inner, outer])
		door_route.append_array(game.navigation.path(outer, game.home_position(owner)))
	route = door_route
	route_index = 0
	game.refuge.set_cutaway(true)

func advance_door(dt: float) -> void:
	var budget := dt * 1.4
	while budget > 0 and door_index < door_route.size():
		var delta := door_route[door_index] - actor.position
		delta.y = 0
		var distance := delta.length()
		if distance < .001:
			door_index += 1
			continue
		var step := minf(distance, budget)
		actor.rotation.y = rotate_toward(actor.rotation.y, atan2(delta.x, delta.z), dt * 9)
		actor.position += delta.normalized() * step
		# The door kit has a 5 cm sill. Lift over it rather than burying the boots.
		var sill_distance := absf(actor.position.z - (game.HOME.z + .9))
		actor.position.y = GROUND_Y + .052 * (1 - smoothstep(.12, .30, sill_distance))
		if actor.position.z < game.HOME.z + .5: inside_refuge = true
		elif actor.position.z > game.HOME.z + 1.25: inside_refuge = false
		anim_time += step / float(ResidentAnimator.SPEEDS.walk)
		budget -= step
		if step >= distance - .001: door_index += 1
	route_index = door_index
	pose("walk", fposmod(anim_time, actor.player.get_animation("walk").length))
	if door_index < door_route.size(): return
	door_active = false
	door_crossings += 1
	inside_refuge = door_entering
	actor.position.y = GROUND_Y
	game.refuge.release(owner)
	if recall_after_door and not inside_refuge:
		recall_after_door = false
		change("return_home")
	else:
		recall_after_door = false
		if not inside_refuge: exit_requested = false
		change("idle")
	pose("idle", 0)

func advance_bridge(dt: float) -> void:
	var delta := bridge_target - actor.position
	var step := minf(delta.length(), dt * 1.2)
	actor.rotation.y = rotate_toward(actor.rotation.y, atan2(delta.x, delta.z), dt * 9)
	actor.position += delta.normalized() * step
	var clip := "carry_walk" if worker.carrying > 0 else "walk"
	anim_time += step / float(ResidentAnimator.SPEEDS[clip])
	pose(clip, fposmod(anim_time, actor.player.get_animation(clip).length))
	if actor.position.distance_to(bridge_target) > .001: return
	actor.position = bridge_target
	bridge_active = false
	bridge_crossings += 1
	route_index += 1
	game.bridge.release(owner)
	if bridge_cancel:
		bridge_cancel = false
		cancel()
