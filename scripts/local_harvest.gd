extends RefCounted
## Orders only. Physical jobs remain in the existing delivery ledger.
const PATCHES := [0, 1, 2, 4, 7]
var game: Node
var targets := {"food": -1, "wood": -1, "fiber": -1, "water": -1}

func priority(id: int) -> int:
	return int(game.patches[id].get("harvest_priority", 2))

func set_priority(id: int, value: int) -> bool:
	if id not in PATCHES or value < 1 or value > 3: return false
	game.patches[id].harvest_priority = value
	return true

func ordered_patches() -> Array[int]:
	var result: Array[int] = []
	for rank in range(1, 4):
		for id in PATCHES:
			if priority(id) == rank: result.append(id)
	return result

func set_active(id: int, active: bool) -> bool:
	if not id in PATCHES or id >= game.patches.size(): return false
	if active and (not game.patches[id].discovered or game.patches[id].amount <= 0): return false
	game.patches[id].autoharvest = active
	return true

func set_target(kind: String, amount: int) -> bool:
	if not targets.has(kind) or amount < -1 or amount > 9999: return false
	targets[kind] = amount
	return true

func expected(kind: String) -> int:
	var amount: int = game.depots.total(kind)
	# Transfers reserve both destination and emergency return space. Count their
	# cargo once after pickup; before pickup it is already in the source stock.
	var transfer_tokens := {}
	for job in game.transfers.jobs.values():
		transfer_tokens[job.token + ":in"] = true
		transfer_tokens[job.token + ":back"] = true
		if job.kind == kind and job.collected and not job.deposited: amount += job.quantity
	for token in game.depots.incoming:
		var claim: Dictionary = game.depots.incoming[token]
		if claim.kind == kind and not transfer_tokens.has(token): amount += claim.quantity
	return amount

func missing(kind: String) -> int:
	return 999999 if targets[kind] < 0 else maxi(0, int(targets[kind]) - expected(kind))

static func valid_targets(value: Variant) -> bool:
	if not value is Dictionary or value.size() != 4: return false
	for kind in ["food", "wood", "fiber", "water"]:
		if not value.has(kind) or not (value[kind] is int or value[kind] is float): return false
		if not is_finite(float(value[kind])) or value[kind] < -1 or value[kind] > 9999 or value[kind] != floor(value[kind]): return false
	return true

func restore_targets(value: Dictionary) -> void:
	for kind in targets: targets[kind] = int(value.get(kind, -1))

func try_start(c: WorkerDelivery) -> bool:
	# Called by priorities only for residents without a manual assignment.
	for id in ordered_patches():
		var p: Dictionary = game.patches[id]
		if not p.get("autoharvest", false) or not p.discovered or p.amount <= p.reserved: continue
		var limit := missing(p.kind)
		if limit <= 0 or game.delivery_ledger.source_slots.has(id): continue
		var target: Vector3 = p.pos + Vector3(.9, WorkerDelivery.GROUND_Y, .2)
		var origin: Vector3 = game.home_position(c.owner) if c.inside_refuge else c.actor.position
		if game.travel_path(origin, target, c.owner).is_empty(): continue
		if game.depots.sink(target, p.kind, mini(limit, mini(3 + game.workshops, p.amount - p.reserved)), c.owner).is_empty(): continue
		if c.inside_refuge:
			c.change("leave_home")
			return true
		if c.start_harvest(id, limit): return true
	return false

func summary(id: int) -> String:
	var p: Dictionary = game.patches[id]
	var text := "%s · gisement %d · %d restant(s)\nPriorité %d" % [game.NAMES[p.kind], id + 1, p.amount, priority(id)]
	if not p.get("autoharvest", false): return text + "\nOrdre suspendu ; les charges engagées se terminent."
	if p.amount <= 0:
		for job in game.delivery_ledger.jobs.values():
			if job.source == id: return text + "\nGisement épuisé ; dernières charges en retour."
		return text + "\nRécolte terminée : gisement épuisé."
	if game.hiding or game.ended or game.pending_save: return text + "\nSuspendu par le rappel ou l’arrêt de la colonie."
	if missing(p.kind) == 0: return text + "\nObjectif atteint ou couvert par les charges engagées (%d/%d)." % [expected(p.kind), targets[p.kind]]
	var engaged := 0
	for job in game.delivery_ledger.jobs.values():
		if job.source == id: engaged += 1
	if engaged > 0: return text + "\n%d charge(s) engagée(s), affectations manuelles comprises." % engaged
	var allowed := false
	for i in range(game.workers.size()):
		if game.workers[i].patch < 0 and game.priorities.value(i, "collect") > 0: allowed = true
	if not allowed: return text + "\nAucun habitant sans affectation autorisé à récolter."
	return text + "\nAttend un habitant disponible, un accès et une place au dépôt."

func marker_text(id: int) -> String:
	var p: Dictionary = game.patches[id]
	var title := "%s · %d" % [game.NAMES[p.kind], p.amount]
	var state := "Sans ordre"
	if p.amount <= 0: state = "Épuisé"
	elif p.get("autoharvest", false):
		if game.ended: state = "Colonie arrêtée"
		elif game.hiding: state = "Rappel"
		elif game.pending_save: state = "Sauvegarde"
		elif targets[p.kind] == 0: state = "Auto suspendu · objectif 0"
		elif missing(p.kind) == 0: state = "Réserve couverte"
		else: state = "Récolte désignée"
	var engaged := 0
	for job in game.delivery_ledger.jobs.values():
		if job.source == id: engaged += 1
	if engaged > 0: state += " · %d porteur(s)" % engaged
	return title + "\n" + state

func marker_rect(id: int) -> Rect2:
	if id not in PATCHES or not game.patches[id].discovered: return Rect2()
	var label: Label3D = game.patches[id].label
	if not label.is_visible_in_tree() or game.camera.is_position_behind(label.global_position): return Rect2()
	var font: Font = label.font if label.font != null else ThemeDB.fallback_font
	var extent := Vector2.ZERO
	var lines := label.text.split("\n")
	for line in lines: extent.x = maxf(extent.x, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, label.font_size).x)
	extent.y = font.get_height(label.font_size) * lines.size() + label.line_spacing * (lines.size() - 1)
	var center: Vector2 = game.camera.unproject_position(label.global_position)
	var unit: float = game.camera.unproject_position(label.global_position + game.camera.global_basis.x).distance_to(center)
	var size := (extent + Vector2.ONE * label.outline_size * 2) * label.pixel_size * unit
	return Rect2(center - size * .5, size).grow(4)

func hit_marker(screen: Vector2) -> int:
	var chosen := -1
	var nearest := INF
	for id in PATCHES:
		var rect := marker_rect(id)
		if rect.has_area() and rect.has_point(screen):
			var distance := screen.distance_squared_to(rect.get_center())
			if distance < nearest:
				chosen = id
				nearest = distance
	return chosen
