extends RefCounted
## Arbitration only at safe handovers; active transactions always settle first.
const KINDS := ["build", "transport", "collect"]
const NAMES := {"collect": "Récolte", "transport": "Transport", "build": "Construction"}
var game: Node

func value(id: int, kind: String) -> int:
	return int(game.workers[id].get("priorities", {}).get(kind, 2))

func set_priority(id: int, kind: String, priority: int) -> void:
	if id < 0 or id >= game.workers.size() or not kind in KINDS or priority < 0 or priority > 3: return
	game.workers[id].priorities[kind] = priority

static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.size() != 3: return false
	for kind in KINDS:
		if not data.has(kind) or not data[kind] is int or data[kind] < 0 or data[kind] > 3: return false
	return true

func start(c: WorkerDelivery) -> bool:
	if game.hiding or game.pending_save or game.ended or c.state != "idle" or c.personal_recall or c.exploring: return false
	if c.job >= 0 or c.supply_job >= 0 or c.furniture_order >= 0 or c.worker.carrying > 0 or c.door_active or c.climbing or c.bridge_active: return false
	if game.torches.occupied(c.owner) or game.fissure.occupied(c.owner): return false
	if c.worker.sleep_requested or c.needs_supply >= 0 or c.need_interrupt or minf(c.worker.nutrition, c.worker.hydration) <= 35: return false
	for rank in range(1, 4):
		for kind in KINDS:
			if value(c.owner, kind) != rank: continue
			match kind:
				"build":
					if game.rooms.start_work(c) or game.fixed_lighting.start_work(c) or game.torches.start_work(c) or game.fissure.start_work(c) or game.sleeping.start_work(c) or game.depots.start_work(c): return true
				"transport":
					if game.construction.start(c) or game.transfers.start(c): return true
				"collect":
					if c.worker.patch >= 0:
						if c.inside_refuge:
							c.change("leave_home")
							return true
						if c.start_harvest(c.worker.patch): return true
					elif game.designations.try_start(c): return true
	return false

func summary() -> String:
	var text := "Les changements s’appliquent au prochain travail. Une charge en cours est déposée avant de changer de tâche."
	for kind in KINDS:
		var enabled := 0
		for id in range(game.workers.size()):
			if value(id, kind) > 0: enabled += 1
		if enabled == 0: text += "\n%s : aucun habitant autorisé." % NAMES[kind]
	return text
