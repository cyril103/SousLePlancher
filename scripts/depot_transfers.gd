extends RefCounted
## Repeating orders; every trip owns source, destination and emergency return space.
var game: Node
var orders: Array = []
var jobs: Dictionary = {}
var cursor := 0

func cycle(source: int, target: int, kind: String, excluded: int = -1) -> bool:
	var pending := [target]
	var seen := {}
	while not pending.is_empty():
		var node: int = pending.pop_back()
		if node == source: return true
		if seen.has(node): continue
		seen[node] = true
		for i in range(orders.size()):
			var order: Dictionary = orders[i]
			if i != excluded and order.active and order.kind == kind and order.source == node: pending.append(order.target)
	return false

func add(source: int, target: int, kind: String) -> bool:
	if source < 0 or target < 0 or source >= game.depots.sites.size() or target >= game.depots.sites.size() or source == target or not kind in game.Depots.KINDS or orders.size() >= 32:
		game._news("Choisissez deux dépôts différents et une ressource valide (32 liaisons maximum).")
		return false
	for order in orders:
		if order.source == source and order.target == target and order.kind == kind:
			game._news("Cette liaison existe déjà ; reprenez-la dans la liste.")
			return false
	if cycle(source, target, kind):
		game._news("Cette liaison créerait une boucle de transport pour la même ressource.")
		return false
	orders.append({"source": source, "target": target, "kind": kind, "active": true, "delivered": 0, "status": "Attend un porteur disponible."})
	return true

func toggle(id: int) -> void:
	var order: Dictionary = orders[id]
	if not order.active and cycle(order.source, order.target, order.kind, id):
		game._news("Reprise impossible : une autre liaison créerait une boucle.")
		return
	order.active = not order.active

func stop(id: int) -> void:
	orders[id].active = false
	for owner in jobs.keys():
		if jobs[owner].order == id: game.workers[owner].delivery.cancel()

func blocked(order: Dictionary) -> String:
	if not order.active: return "En pause ; les trajets déjà engagés se terminent."
	if game.hiding or game.ended: return "Suspendu par le rappel ou l’arrêt de la colonie."
	for id in [order.source, order.target]:
		if id > 0 and not game.depots.sites[id].built: return "Attend la construction des dépôts."
	if not order.kind in game.depots.sites[order.target].filters: return "Filtre de destination fermé."
	if game.depots.available(order.source, order.kind) <= 0: return "Source vide ou déjà réservée."
	if game.depots.free_space(order.target) <= 0: return "Destination pleine ou places réservées."
	return ""

func start(c: WorkerDelivery) -> bool:
	if jobs.has(c.owner): return false
	for offset in range(orders.size()):
		var id := (cursor + offset) % orders.size()
		var order: Dictionary = orders[id]
		if not blocked(order).is_empty(): continue
		var count := 0
		for job in jobs.values():
			if job.order == id: count += 1
		if count >= 2: continue
		var from: Vector3 = game.home_position(c.owner) if c.inside_refuge else c.actor.position
		if game.travel_path(from, game.depots.entry(order.source), c.owner).is_empty() or game.travel_path(game.depots.entry(order.source), game.depots.entry(order.target), c.owner).is_empty():
			order.status = "Trajet inaccessible : dégager les accès."
			continue
		if c.inside_refuge:
			c.change("leave_home")
			return true
		var quantity: int = mini(3 + game.workshops, mini(game.depots.available(order.source, order.kind), game.depots.free_space(order.target)))
		var token := "transfer:%d" % c.owner
		game.depots.reserve_out(token + ":out", order.source, order.kind, quantity)
		game.depots.reserve_in(token + ":in", {"id": order.target, "kind": order.kind, "quantity": quantity})
		jobs[c.owner] = {"order": id, "source": order.source, "target": order.target, "kind": order.kind, "quantity": quantity, "token": token, "ticket": -3000000000 - c.owner, "collected": false, "deposited": false, "returning": false}
		c.worker.kind = order.kind
		c.set_depot(order.source)
		c.change("transfer_wait")
		order.status = "Transport en cours."
		cursor = (id + 1) % orders.size()
		return true
	return false

func finish(c: WorkerDelivery) -> void:
	var job: Dictionary = jobs[c.owner]
	for depot in [job.source, job.target]: game.depots.gate(depot).release_destination(job.ticket)
	for suffix in [":out", ":in", ":back"]: game.depots.release(job.token + suffix)
	jobs.erase(c.owner)
	c.actor.cargo.hide()
	c.set_depot(0)
	c.change("return_home" if game.hiding or c.personal_recall or c.worker.sleep_requested or c.need_interrupt else "idle")

func cancel(c: WorkerDelivery) -> bool:
	if not jobs.has(c.owner): return false
	var job: Dictionary = jobs[c.owner]
	c.personal_recall = true
	if job.deposited: return true
	if not job.collected:
		finish(c)
		return true
	game.depots.gate(job.target).release_destination(job.ticket)
	game.depots.release(job.token + ":in")
	job.returning = true
	c.set_depot(job.source)
	c.change("transfer_wait")
	return true

func tick(c: WorkerDelivery, dt: float) -> bool:
	if not jobs.has(c.owner): return false
	var job: Dictionary = jobs[c.owner]
	var depot: int = job.source if not job.collected or job.returning else job.target
	match c.state:
		"transfer_wait":
			if not c.depot_reachable():
				game.depots.gate(depot).release_destination(job.ticket)
				c.navigation_issue = "Transfert bloqué : dégager l’accès au dépôt."
				c.pose("pick_up" if job.collected else "idle", 1.8 if job.collected else 0.0)
			elif game.depots.gate(depot).acquire_slot(job.ticket):
				c.navigation_issue = ""
				c.change("transfer_drop_walk" if job.collected else "transfer_pick_walk")
			else:
				if c.move(game.depots.waiting(depot, c.owner), dt, job.collected): c.pose("pick_up" if job.collected else "idle", 1.8 if job.collected else 0.0)
		"transfer_pick_walk", "transfer_drop_walk":
			if c.move(game.depots.entry(depot), dt, job.collected):
				c.actor.rotation.y = 0
				if not job.collected:
					c.actor.cargo.reparent(game, true)
					c.actor.cargo.global_transform = Transform3D(Basis.IDENTITY, game.depots.entry(depot)) * c.contact
					c.actor.cargo.show()
				c.change("transfer_drop" if job.collected else "transfer_pickup")
			elif not c.navigation_issue.is_empty():
				if not job.collected: cancel(c)
				else:
					game.depots.gate(depot).release_destination(job.ticket)
					c.change("transfer_wait")
		"transfer_pickup":
			c.pose("pick_up", minf(c.timer, 1.8))
			if c.timer >= c.CAPTURE_TIME and not job.collected:
				game.depots.withdraw(job.token + ":out")
				game.depots.reserve_in(job.token + ":back", {"id": job.source, "kind": job.kind, "quantity": job.quantity})
				job.collected = true
				c.worker.carrying = job.quantity
				c.actor.cargo.reparent(c.cargo_socket, false)
				c.actor.cargo.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * .52), Vector3.ZERO)
			if c.timer >= 1.8:
				game.depots.gate(job.source).release_destination(job.ticket)
				c.set_depot(job.target)
				c.change("transfer_wait")
		"transfer_drop":
			c.pose("put_down", minf(c.timer, 1.8))
			if c.timer >= c.DEPOSIT_TIME and not job.deposited:
				c.actor.cargo.reparent(game, true)
				c.actor.cargo.global_transform = Transform3D(Basis.IDENTITY, game.depots.entry(depot)) * c.contact
				game.depots.deposit(job.token + (":back" if job.returning else ":in"))
				game.depots.release(job.token + (":in" if job.returning else ":back"))
				c.worker.carrying = 0
				job.deposited = true
				if not job.returning: orders[job.order].delivered += job.quantity
				c.completed_deliveries += 1
			if c.timer >= 1.8: finish(c)
	return true

func description(c: WorkerDelivery) -> String:
	if not jobs.has(c.owner): return ""
	if not c.navigation_issue.is_empty(): return c.navigation_issue
	var job: Dictionary = jobs[c.owner]
	return "%s · %d %s · dépôt %d → %d" % ["Retour de charge" if job.returning else "Transfert", job.quantity, game.NAMES[job.kind], job.source, job.target]

func summary(id: int) -> String:
	var order: Dictionary = orders[id]
	var reason := blocked(order)
	var text := "%s · %s → %s\n%d livré(s) · %s" % [game.NAMES[order.kind], "Refuge" if order.source == 0 else "Dépôt %d" % order.source, "Refuge" if order.target == 0 else "Dépôt %d" % order.target, order.delivered, reason if not reason.is_empty() else order.status]
	for owner in jobs:
		if jobs[owner].order == id: text += "\nH%d · %s" % [owner + 1, description(game.workers[owner].delivery)]
	return text

func snapshot() -> Dictionary:
	return {"orders": orders.duplicate(true), "jobs": jobs.duplicate(true), "cursor": cursor}

func restore(data: Dictionary) -> void:
	orders = data.get("orders", []).duplicate(true)
	jobs = data.get("jobs", {}).duplicate(true)
	cursor = int(data.get("cursor", 0))

static func valid(value: Variant, runtime: Dictionary, data: Dictionary) -> bool:
	if not value is Dictionary or not value.has_all(["orders", "jobs", "cursor"]): return false
	if not value.orders is Array or value.orders.size() > 32 or not value.jobs is Dictionary or not value.cursor is int: return false
	if value.cursor < 0 or value.cursor >= maxi(1, value.orders.size()): return false
	var duplicates := {}
	for order in value.orders:
		if not order is Dictionary or not order.has_all(["source", "target", "kind", "active", "delivered", "status"]): return false
		for key in ["source", "target"]:
			if not order[key] is int or order[key] < 0 or order[key] >= data.depots.size(): return false
		if order.source == order.target or not order.kind in ["food", "water", "wood", "fiber"] or not order.active is bool or not order.delivered is int or order.delivered < 0 or not order.status is String: return false
		var key := "%s:%d:%d" % [order.kind, order.source, order.target]
		if duplicates.has(key): return false
		duplicates[key] = true
	# Active links must form an acyclic graph for each resource.
	for order in value.orders:
		if not order.active: continue
		var pending := [order.target]
		var seen := {}
		while not pending.is_empty():
			var current: int = pending.pop_back()
			if current == order.source: return false
			if seen.has(current): continue
			seen[current] = true
			for other in value.orders:
				if other.active and other.kind == order.kind and other.source == current: pending.append(other.target)
	var incoming := {}
	var outgoing := {}
	var counts := {}
	for owner in value.jobs:
		if not owner is int or owner < 0 or owner >= runtime.workers.size(): return false
		var job = value.jobs[owner]
		if not job is Dictionary or not job.has_all(["order", "source", "target", "kind", "quantity", "token", "ticket", "collected", "deposited", "returning"]): return false
		if not job.order is int or job.order < 0 or job.order >= value.orders.size(): return false
		var order: Dictionary = value.orders[job.order]
		for key in ["source", "target", "kind"]:
			if job[key] != order[key]: return false
		if not job.quantity is int or job.quantity < 1 or job.quantity > 67 or job.token != "transfer:%d" % owner or job.ticket != -3000000000 - owner: return false
		for key in ["collected", "deposited", "returning"]:
			if not job[key] is bool: return false
		if (job.deposited or job.returning) and not job.collected: return false
		counts[job.order] = counts.get(job.order, 0) + 1
		if counts[job.order] > 2: return false
		for id in [job.source, job.target]:
			if id > 0 and not data.depots[id].built: return false
		var w: Dictionary = runtime.workers[owner]
		if not w.controller.state in ["transfer_wait", "transfer_pick_walk", "transfer_pickup", "transfer_drop_walk", "transfer_drop"] or w.controller.job >= 0 or w.controller.supply_job >= 0 or runtime.torch_missions.has(owner): return false
		if w.worker.carrying != (job.quantity if job.collected and not job.deposited else 0): return false
		if job.collected and not job.deposited and w.worker.kind != job.kind: return false
		if not job.collected: outgoing[job.token + ":out"] = {"id": job.source, "kind": job.kind, "quantity": job.quantity}
		if not job.deposited:
			if not job.returning: incoming[job.token + ":in"] = {"id": job.target, "kind": job.kind, "quantity": job.quantity}
			if job.collected: incoming[job.token + ":back"] = {"id": job.source, "kind": job.kind, "quantity": job.quantity}
	for expected in [incoming, outgoing]:
		var actual: Dictionary = runtime.incoming if is_same(expected, incoming) else runtime.outgoing
		for token in expected:
			if not actual.has(token) or actual[token] != expected[token]: return false
		for token in actual:
			if str(token).begins_with("transfer:") and not expected.has(token): return false
	for i in range(runtime.workers.size()):
		if str(runtime.workers[i].controller.state).begins_with("transfer_") and not value.jobs.has(i): return false
	return true
