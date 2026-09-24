extends RefCounted
## Physical supply tasks. Depot reservation, carried load and site stock are distinct.
var game: Node3D
var jobs: Dictionary = {}
var recovery: Array[Dictionary] = []
var next_id := 1

func cost(bed: Dictionary) -> Dictionary:
	return game.COSTS["private_bed" if bed.private else "bed"]

func supplied(bed: Dictionary) -> bool:
	for kind in cost(bed):
		if bed.materials[kind] < cost(bed)[kind]: return false
	return true

func reserved(kind: String) -> int:
	var count := 0
	for job in jobs.values():
		if job.kind == kind and job.source.is_empty() and not job.collected: count += job.quantity
	return count

func available(kind: String) -> int:
	return game.depots.total_available(kind)

func for_site(bed: Dictionary, kind: String) -> int:
	# Older sites get first choice, even while their porter is bringing another kind.
	# This prevents scarce fibres being scattered across several unfinished beds.
	var amount := available(kind)
	for earlier in game.sleeping.beds:
		if earlier == bed: break
		if earlier.built: continue
		var missing: int = cost(earlier)[kind] - earlier.materials[kind]
		for job in jobs.values():
			if job.target == earlier and job.kind == kind and not job.deposited: missing -= job.quantity
		amount -= maxi(0, missing)
	return maxi(0, amount)

func status(bed: Dictionary) -> String:
	if bed.built: return "Terminé"
	if supplied(bed):
		return "Fabrication %d %%" % int(100 * bed.work / bed.required) if bed.builder >= 0 else "Prêt à fabriquer"
	if bed.hauler >= 0: return "Transport en cours"
	for kind in ["wood", "fiber"]:
		if bed.materials[kind] < cost(bed)[kind] and for_site(bed, kind) <= 0: return "Matériaux manquants"
	return "Attend un porteur"

func quantities(bed: Dictionary) -> String:
	return "Bois %d/%d · Fibres %d/%d" % [bed.materials.wood, cost(bed).wood, bed.materials.fiber, cost(bed).fiber]

func start(c: WorkerDelivery) -> bool:
	# Called only at the normal safe handover, after personal needs and cargo settlement.
	var from: Vector3 = game.home_position(c.owner) if c.inside_refuge else c.actor.position
	for pile in recovery:
		if pile.hauler >= 0: continue
		if game.travel_path(from, pile.pos, c.owner).is_empty(): continue
		for kind in ["wood", "fiber"]:
			if pile.materials[kind] > 0:
				var choice: Dictionary = game.depots.sink(pile.pos, kind, mini(pile.materials[kind], 3 + game.workshops), c.owner)
				if not choice.is_empty(): return begin(c, kind, choice.quantity, pile, {}, choice.id)
	for bed in game.sleeping.beds:
		if bed.built or bed.hauler >= 0 or supplied(bed): continue
		for kind in ["wood", "fiber"]:
			var depot: int = game.depots.source(from, kind, c.owner, game.sleeping.entrance(bed))
			if depot < 0: continue
			var quantity := mini(int(cost(bed)[kind]) - int(bed.materials[kind]), mini(for_site(bed, kind), mini(game.depots.available(depot, kind), 3 + game.workshops)))
			if quantity > 0: return begin(c, kind, quantity, {}, bed, depot)
	return false

func begin(c: WorkerDelivery, kind: String, quantity: int, source: Dictionary, target: Dictionary, depot: int) -> bool:
	if c.inside_refuge:
		c.change("leave_home")
		return true
	var id := next_id
	next_id += 1
	var token := "s:%d" % id
	if source.is_empty(): game.depots.reserve_out(token, depot, kind, quantity)
	else: game.depots.reserve_in(token, {"id": depot, "kind": kind, "quantity": quantity})
	jobs[id] = {"owner": c.owner, "kind": kind, "quantity": quantity, "source": source, "target": target, "depot": depot, "token": token,
		"collected": false, "deposited": false, "returning": target.is_empty(), "ticket": -id - 1}
	if not source.is_empty(): source.hauler = c.owner
	if not target.is_empty(): target.hauler = c.owner
	c.supply_job = id
	c.set_depot(depot)
	c.worker.kind = kind
	c.change("supply_pick_walk" if not source.is_empty() else "supply_wait")
	if not target.is_empty(): game.sleeping.caption(game.sleeping.beds.find(target))
	return true

func release_claims(job: Dictionary) -> void:
	if not job.source.is_empty(): job.source.hauler = -1
	if not job.target.is_empty(): job.target.hauler = -1
	game.depots.gate(job.depot).release_destination(job.ticket)
	game.depots.release(job.token)
	if not job.target.is_empty(): game.sleeping.caption(game.sleeping.beds.find(job.target))

func finish(c: WorkerDelivery) -> void:
	var job: Dictionary = jobs[c.supply_job]
	jobs.erase(c.supply_job)
	release_claims(job)
	c.supply_job = -1
	c.set_depot(0)
	c.actor.cargo.hide()
	c.change("return_home" if game.hiding or c.personal_recall or c.worker.sleep_requested or c.need_interrupt else "idle")
	c.pose("idle", 0)
	clean_recovery()

func cancel(c: WorkerDelivery) -> bool:
	if c.supply_job < 0: return false
	var job: Dictionary = jobs[c.supply_job]
	c.personal_recall = true
	# A completed deposit only needs its animation and slot release to finish.
	if job.deposited: return true
	if not job.collected:
		finish(c)
		return true
	if not job.target.is_empty():
		job.target.hauler = -1
		game.sleeping.caption(game.sleeping.beds.find(job.target))
	job.target = {}
	job.returning = true
	game.depots.gate(job.depot).release_destination(job.ticket)
	c.change("supply_wait")
	return true

func source_position(c: WorkerDelivery, job: Dictionary) -> Vector3:
	return c.destination_position if job.source.is_empty() else job.source.pos

func target_position(c: WorkerDelivery, job: Dictionary) -> Vector3:
	return c.destination_position if job.returning else game.sleeping.entrance(job.target)

func tick(c: WorkerDelivery, dt: float) -> bool:
	if c.supply_job < 0: return false
	var job: Dictionary = jobs[c.supply_job]
	match c.state:
		"supply_wait":
			if job.returning and not c.depot_reachable():
				var previous: int = job.depot
				if game.depots.reroute(job.token, c.actor.position, c.owner):
					job.depot = game.depots.incoming[job.token].id
					c.set_depot(job.depot)
					if previous != job.depot: game.depots.gate(previous).release_destination(job.ticket)
			if c.depot_reachable() and game.depots.gate(job.depot).acquire_slot(job.ticket):
				c.change("supply_drop_walk" if job.collected else "supply_pick_walk")
			else:
				if not c.depot_reachable(): game.depots.gate(job.depot).release_destination(job.ticket)
				if c.move(game.depots.waiting(job.depot, c.owner), dt, job.collected): c.pose("pick_up" if job.collected else "idle", 1.8 if job.collected else 0.0)
				if not c.depot_reachable(): c.navigation_issue = "Accès au dépôt bloqué"
		"supply_pick_walk":
			if c.move(source_position(c, job), dt, false):
				c.actor.rotation.y = 0
				c.actor.cargo.reparent(game, true)
				c.actor.cargo.global_transform = Transform3D(Basis.IDENTITY, source_position(c, job)) * c.contact
				c.actor.cargo.show()
				c.change("supply_pickup")
			elif not c.navigation_issue.is_empty(): cancel(c)
		"supply_pickup":
			c.pose("pick_up", minf(c.timer, 1.8))
			if c.timer >= c.CAPTURE_TIME and not job.collected:
				if job.source.is_empty(): game.depots.withdraw(job.token, true)
				else:
					job.source.materials[job.kind] -= job.quantity
					recovery_visual(job.source)
				job.collected = true
				c.worker.carrying = job.quantity
				c.actor.cargo.reparent(c.cargo_socket, false)
				c.actor.cargo.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * .52), Vector3.ZERO)
			if c.timer >= 1.8:
				game.depots.gate(job.depot).release_destination(job.ticket)
				c.change("supply_wait" if job.returning else "supply_drop_walk")
		"supply_drop_walk":
			if c.move(target_position(c, job), dt, true):
				c.actor.rotation.y = 0
				c.change("supply_drop")
			elif not c.navigation_issue.is_empty():
				if job.returning:
					game.depots.gate(job.depot).release_destination(job.ticket)
					c.change("supply_wait")
				else: cancel(c)
		"supply_drop":
			c.pose("put_down", minf(c.timer, 1.8))
			if c.timer >= c.DEPOSIT_TIME and not job.deposited:
				c.actor.cargo.reparent(game, true)
				c.actor.cargo.global_transform = Transform3D(Basis.IDENTITY, target_position(c, job)) * c.contact
				if job.returning: game.depots.deposit(job.token)
				else:
					game.depots.release(job.token)
					job.target.materials[job.kind] += job.quantity
					game.sleeping.visual(game.sleeping.beds.find(job.target))
				job.deposited = true
				c.worker.carrying = 0
			if c.timer >= 1.8: finish(c)
	return true

func cancel_site(bed: Dictionary) -> void:
	# Keep the already-delivered material in the world; pickup is a normal task.
	if bed.materials.wood + bed.materials.fiber > 0:
		add_recovery(game.sleeping.entrance(bed), bed.materials.duplicate())
	for cdata in game.workers:
		var c: WorkerDelivery = cdata.delivery
		if c.supply_job >= 0 and jobs[c.supply_job].target == bed:
			var job: Dictionary = jobs[c.supply_job]
			if job.deposited: finish(c)
			else: cancel(c)

func add_recovery(pos: Vector3, materials: Dictionary) -> void:
	var node := Node3D.new()
	game.add_child(node)
	node.position = pos
	var label: Label3D = game.Art.caption(node, "", Vector3(0, .8, 0))
	label.pixel_size = .004
	var pile := {"pos": pos, "materials": materials, "hauler": -1, "node": node, "label": label}
	recovery.append(pile)
	recovery_visual(pile)

func recovery_visual(pile: Dictionary) -> void:
	for child in pile.node.get_children():
		if child == pile.label: continue
		pile.node.remove_child(child)
		child.queue_free()
	for kind in ["wood", "fiber"]:
		if pile.materials[kind] <= 0: continue
		var mesh: Node3D = game.Art.model(pile.node, kind, Vector3(-.25 if kind == "wood" else .25, 0, 0))
		mesh.scale = Vector3.ONE * .4
	pile.label.text = "À récupérer · %d bois · %d fibres" % [pile.materials.wood, pile.materials.fiber]
	pile.node.visible = pile.materials.wood + pile.materials.fiber > 0

func clean_recovery() -> void:
	for i in range(recovery.size() - 1, -1, -1):
		var pile := recovery[i]
		if pile.hauler == -1 and pile.materials.wood + pile.materials.fiber == 0:
			pile.node.queue_free()
			recovery.remove_at(i)

func snapshot() -> Array:
	var result: Array = []
	for pile in recovery:
		result.append({"pos": game.Save.vector(pile.pos), "materials": pile.materials.duplicate()})
	return result

func description(c: WorkerDelivery) -> String:
	if c.supply_job < 0: return ""
	if not c.navigation_issue.is_empty(): return c.navigation_issue
	var job: Dictionary = jobs[c.supply_job]
	var action: String = {"supply_wait": "Attend le dépôt", "supply_pick_walk": "Va chercher", "supply_pickup": "Prend", "supply_drop_walk": "Rapporte" if job.returning else "Livre au chantier", "supply_drop": "Dépose au dépôt" if job.returning else "Dépose au chantier"}.get(c.state, "Approvisionne")
	return "%s · %d %s" % [action, job.quantity, game.NAMES[job.kind].to_lower()]
