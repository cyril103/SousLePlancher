extends RefCounted
## One finite source; claims are held from departure to delivery or cancellation.
var game: Node3D
var amount := 24
var reserved := 0
var known := -1
var model: Node3D

func setup() -> void:
	model = game.Art.model(game, "fiber", Vector3(3, 0, 12.9))
	model.scale = Vector3.ONE * .65
	model.hide()

func refresh() -> void:
	if not is_instance_valid(model): return
	var visible_now: bool = game.fissure.observed()
	if visible_now: known = amount
	model.visible = visible_now and amount > 0

func summary() -> String:
	if not game.fissure.visited: return "Ressources à reconnaître"
	return "Fibres : %s · %d réservées" % [str(known) + " vues" if known >= 0 else "inconnues", reserved]

func start(id: int) -> bool:
	var p = game.fissure
	if not p.visited: return p.reject("Reconnaissez d’abord l’alcôve à la lanterne.")
	if not p.widened(): return p.reject("Élargissez le passage avant de rapporter une caisse.")
	if amount <= reserved: return p.reject("Les fibres sont épuisées ou déjà réservées.")
	var c: WorkerDelivery = game.workers[id].delivery
	var choice: Dictionary = game.depots.sink(p.NEAR, "fiber", mini(3 + game.workshops, amount - reserved), id)
	if choice.is_empty(): return p.reject("Aucun dépôt accessible n’a de place pour les fibres.")
	var index: int = game.torches.held(id)
	if index < 0 or not game.torches.can_haul(id): return p.reject("Équipez une lanterne de ceinture et attendez sa récupération.")
	var required: float = p.required_fuel(c) + game.torches.travel_seconds(c, p.NEAR, game.depots.entry(choice.id)) + game.torches.travel_seconds(c, game.depots.entry(choice.id), game.HOME + game.Refuge.OUTSIDE) + 12
	if game.torches.items[index].fuel < required: return p.reject("Autonomie insuffisante pour prélever, livrer et rentrer avec une marge (%.0f s)." % required)
	if not p.start(id): return false
	var m: Dictionary = p.missions[id]
	m.quantity = choice.quantity
	m.depot = choice.id
	m.token = "alcove:%d" % id
	m.ticket = -2000000000 + id
	m.collected = false
	m.deposited = false
	m.released = false
	reserved += int(choice.quantity)
	game.depots.reserve_in(m.token, choice)
	c.worker.kind = "fiber"
	game._news("H%d : %d fibres et leur place au dépôt réservées. Un aller-retour éclairé." % [id + 1, choice.quantity])
	return true

func cancel_uncollected(c: WorkerDelivery, m: Dictionary) -> void:
	if not m.has("quantity") or m.collected or m.released: return
	reserved -= int(m.quantity)
	game.depots.release(m.token)
	m.released = true
	c.actor.cargo.hide()

func release(c: WorkerDelivery, m: Dictionary) -> void:
	if not m.has("quantity"): return
	assert(c.worker.carrying == 0)
	cancel_uncollected(c, m)
	game.depots.gate(m.depot).release_destination(m.ticket)
	game.depots.release(m.token)
	c.actor.cargo.hide()
	c.set_depot(0)

func tick(c: WorkerDelivery, m: Dictionary, dt: float) -> bool:
	if not m.has("quantity"): return false
	var p = game.fissure
	match m.phase:
		"harvest_walk":
			if p.local_move(c, p.LOOK + Vector3((c.owner - 1.5) * .45, 0, 0), dt):
				m.phase = "harvest"
				m.clock = 0.0
		"harvest":
			c.pose("work", fposmod(m.clock, 1.2))
			m.clock += dt
			if m.clock >= 3:
				c.actor.rotation.y = 0
				c.actor.cargo.reparent(game, true)
				c.actor.cargo.global_transform = Transform3D(Basis.IDENTITY, c.actor.position) * c.contact
				c.actor.cargo.show()
				m.phase = "harvest_pickup"
				m.clock = 0.0
		"harvest_pickup":
			m.clock += dt
			c.pose("pick_up", minf(m.clock, 1.8))
			if m.clock >= c.CAPTURE_TIME and not m.collected:
				amount -= int(m.quantity)
				reserved -= int(m.quantity)
				m.collected = true
				c.worker.carrying = m.quantity
				c.actor.cargo.reparent(c.cargo_socket, false)
				c.actor.cargo.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * .52), Vector3.ZERO)
				refresh()
			if m.clock >= 1.8:
				m.returning = true
				m.phase = "back"
		"delivery_wait":
			# Preserve the reservation and crate if access is blocked; reroute only
			# to a depot able to accept the entire load.
			if game.depots.reroute(m.token, c.actor.position, c.owner):
				var target: int = game.depots.incoming[m.token].id
				if target != m.depot:
					game.depots.gate(m.depot).release_destination(m.ticket)
					m.depot = target
				c.set_depot(m.depot)
				if game.depots.gate(m.depot).acquire_slot(m.ticket):
					m.phase = "delivery_walk"
				else:
					if c.move(game.depots.waiting(m.depot, c.owner), dt, true): c.pose("pick_up", 1.8)
			else:
				game.depots.gate(m.depot).release_destination(m.ticket)
				c.navigation_issue = "Livraison bloquée : dégager l’accès au dépôt"
				c.pose("pick_up", 1.8)
		"delivery_walk":
			if c.move(game.depots.entry(m.depot), dt, true):
				c.actor.rotation.y = 0
				m.phase = "delivery_drop"
				m.clock = 0.0
			elif not c.navigation_issue.is_empty():
				game.depots.gate(m.depot).release_destination(m.ticket)
				m.phase = "delivery_wait"
		"delivery_drop":
			m.clock += dt
			c.pose("put_down", minf(m.clock, 1.8))
			if m.clock >= c.DEPOSIT_TIME and not m.deposited:
				c.actor.cargo.reparent(game, true)
				c.actor.cargo.global_transform = Transform3D(Basis.IDENTITY, game.depots.entry(m.depot)) * c.contact
				var delivered: int = game.depots.deposit(m.token)
				assert(delivered == c.worker.carrying)
				c.worker.carrying = 0
				c.completed_deliveries += 1
				m.deposited = true
				game._news("H%d a livré %d fibres de l’alcôve. Elles peuvent approvisionner un lit." % [c.owner + 1, delivered])
			if m.clock >= 1.8: p.finish(c)
		_:
			return false
	return true

func description(c: WorkerDelivery, m: Dictionary) -> String:
	if not c.navigation_issue.is_empty(): return c.navigation_issue
	var action: String = {"harvest_walk": "Rejoint les fibres", "harvest": "Prépare les fibres", "harvest_pickup": "Prend la caisse", "delivery_wait": "Attend le dépôt", "delivery_walk": "Rapporte les fibres", "delivery_drop": "Dépose les fibres"}.get(m.phase, "Rapporte la caisse" if c.worker.carrying > 0 else "Va chercher les fibres")
	return ("Alcôve · " if c.sector_id == game.fissure.ALCOVE_SECTOR else "Refuge · ") + action + " · %d fibres" % m.quantity
