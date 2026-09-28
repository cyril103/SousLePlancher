extends RefCounted
## Versioned colony data and a data-only snapshot of active simulation.
const VERSION := 25
const Live = preload("res://scripts/live_checkpoint.gd")
const DEFAULT_PATH := "user://saves/colony_v1.json"
const KINDS := ["food", "food", "wood", "wood", "fiber", "fiber", "wood", "water"]

static func capture(game: Node) -> Dictionary:
	var buildings: Array = []
	for building in game.buildings:
		if building.kind != "heart": buildings.append({"kind": building.kind, "pos": vector(building.pos)})
	var patches: Array = []
	for patch in game.patches: patches.append({"kind": patch.kind, "amount": patch.amount, "discovered": patch.discovered, "autoharvest": patch.get("autoharvest", false)})
	var assignments: Array = []
	for worker in game.workers: assignments.append(worker.patch)
	var needs: Array = []
	for worker in game.workers:
		needs.append({"energy": worker.energy, "comfort": worker.comfort, "privacy": worker.privacy, "sleep_requested": worker.sleep_requested,
			"nutrition": worker.nutrition, "hydration": worker.hydration})
	var stocks: Dictionary = game.stock.duplicate()
	stocks.water = int(stocks.get("water", 0))
	return {
		"format": "SousLePlancher/checkpoint", "version": VERSION,
		"saved_at": Time.get_datetime_string_from_system(),
		"runtime": Live.capture(game),
		"stock": stocks, "patches": patches, "buildings": buildings,
		"assignments": assignments, "speed": game.speed,
		"harvest_targets": game.local_harvest.targets.duplicate(),
		"needs": needs, "furnishings": game.sleeping.snapshot(),
		"recovery": game.construction.snapshot(),
		"depots": game.depots.snapshot(),
		"torches": game.torches.snapshot(),
		"fissure": game.fissure.snapshot(),
		"water_source": vector(game.patches[7].pos),
		"clock": {"elapsed": game.elapsed, "meal_timer": game.meal_timer, "suspicion": game.suspicion, "hunger": game.hunger, "event_index": game.event_index},
		"view": {"focus": vector(game.focus), "yaw": game.yaw, "zoom": game.zoom, "paths": game.show_paths, "resident": game.hud.resident_index, "cutaway": game.refuge.cutaway}
	}

static func vector(value: Vector3) -> Array:
	return [value.x, value.y, value.z]

static func fields(value: Variant, keys: Array) -> bool:
	return value is Dictionary and value.has_all(keys)

static func number(value: Variant, low: float, high: float, integral: bool = false) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT: return false
	return is_finite(float(value)) and value >= low and value <= high and (not integral or value == floor(value))

static func valid_vector(value: Variant) -> bool:
	if not value is Array or value.size() != 3: return false
	for component in value:
		if not number(component, -100, 100): return false
	return true

static func validate(data: Variant) -> String:
	if not fields(data, ["format", "version", "saved_at", "stock", "patches", "buildings", "assignments", "clock", "view", "speed"]): return "Sauvegarde incomplète."
	if data.format != "SousLePlancher/checkpoint" or not number(data.version, 1, VERSION, true): return "Version de sauvegarde incompatible."
	if not data.saved_at is String or data.saved_at.length() > 64: return "Date de sauvegarde invalide."
	if not fields(data.stock, ["food", "wood", "fiber"]): return "Stocks incomplets."
	for kind in ["food", "wood", "fiber"]:
		if not number(data.stock[kind], 0, 100000000, true): return "Stock invalide."
	if data.version >= 3 and (not data.stock.has("water") or not number(data.stock.water, 0, 100000000, true)): return "Réserve d’eau invalide."
	if data.version >= 3:
		if not data.has("water_source") or not valid_vector(data.water_source) or data.water_source[1] != 0: return "Point d’eau invalide."
		if absf(data.water_source[0]) > 9 or absf(data.water_source[2]) > 6: return "Point d’eau hors de la carte."
	if data.version >= 23 or data.has("harvest_targets"):
		if not preload("res://scripts/local_harvest.gd").valid_targets(data.get("harvest_targets")): return "Objectifs de récolte invalides."
	var count := 8 if data.version >= 3 else 7
	if not data.patches is Array or data.patches.size() != count: return "Carte de ressources incompatible."
	for i in range(count):
		var patch = data.patches[i]
		if not fields(patch, ["kind", "amount", "discovered"]): return "Gisement incomplet."
		if patch.kind != KINDS[i] or not number(patch.amount, 0, 100000000, true) or not patch.discovered is bool: return "Gisement invalide."
		if data.version >= 22 or patch.has("autoharvest"):
			if not patch.get("autoharvest") is bool: return "Ordre de récolte locale invalide."
			if patch.autoharvest and (not i in preload("res://scripts/local_harvest.gd").PATCHES or not patch.discovered): return "Ordre de récolte hors du refuge."
		if i < 6 and not patch.discovered: return "Gisement initial manquant."
		if i == 7 and not patch.discovered: return "Point d’eau initial manquant."
	if not data.buildings is Array or data.buildings.size() > 64: return "Bâtiments invalides."
	var shelters := 0
	var depot_count := 1
	var furnishings: Array = []
	for building in data.buildings:
		if not fields(building, ["kind", "pos"]) or not valid_vector(building.pos): return "Bâtiment incomplet."
		if not building.kind in ["shelter", "workshop", "bed", "private_bed", "depot"]: return "Type de bâtiment inconnu."
		if building.kind == "depot":
			if data.version < 5: return "Dépôt incompatible avec l’ancien format."
			depot_count += 1
		if building.kind in ["bed", "private_bed"]: furnishings.append(building.kind)
		var east_depot: bool = data.version >= 11 and building.kind == "depot" and Vector3(building.pos[0], building.pos[1], building.pos[2]).is_equal_approx(Vector3(11.2, 2.04, -3.7))
		if not east_depot and (building.pos[1] != 0 or not number(building.pos[0], -19 if data.version >= 15 else -9, 19 if data.version >= 15 else 9, true) or not number(building.pos[2], -11 if data.version >= 15 else -6, 11 if data.version >= 15 else 6, true)): return "Emplacement de bâtiment invalide."
		if east_depot and not data.patches[6].discovered: return "Dépôt dans une réserve inconnue."
		if building.kind == "shelter": shelters += 1
	if shelters > 2 or not data.assignments is Array or data.assignments.size() != 4 + shelters: return "Population incompatible avec les abris."
	if data.version == 1 and not furnishings.is_empty(): return "Couchages incompatibles avec l’ancien format."
	if data.version >= 2:
		if not fields(data, ["needs", "furnishings"]) or not data.needs is Array or data.needs.size() != data.assignments.size(): return "Besoins incomplets."
		for need in data.needs:
			if not fields(need, ["energy", "comfort", "privacy", "sleep_requested"]): return "Besoin incomplet."
			for key in ["energy", "comfort", "privacy"]:
				if not number(need[key], 0, 100): return "Besoin invalide."
			if not need.sleep_requested is bool: return "Repos invalide."
			if data.version >= 3:
				if not fields(need, ["nutrition", "hydration"]): return "Besoins vitaux incomplets."
				for key in ["nutrition", "hydration"]:
					if not number(need[key], 0, 100): return "Besoin vital invalide."
		if not data.furnishings is Array or data.furnishings.size() != furnishings.size(): return "Couchages incomplets."
		var owners: Array = []
		for i in range(furnishings.size()):
			var bed = data.furnishings[i]
			var required := 20.0 if furnishings[i] == "private_bed" else 12.0
			if not fields(bed, ["owner", "work", "built"]): return "Couchage incomplet."
			if not number(bed.owner, -1, data.assignments.size() - 1, true) or not number(bed.work, 0, required) or not bed.built is bool: return "Couchage invalide."
			if bed.built != (bed.work == required): return "Avancement du couchage incohérent."
			if data.version >= 4:
				var amounts := {"wood": 6, "fiber": 5} if furnishings[i] == "private_bed" else {"wood": 4, "fiber": 3}
				if not fields(bed, ["materials"]) or not fields(bed.materials, ["wood", "fiber"]): return "Matériaux de chantier manquants."
				for kind in amounts:
					if not number(bed.materials[kind], 0, amounts[kind], true): return "Matériaux de chantier invalides."
					if bed.work > 0 and bed.materials[kind] != amounts[kind]: return "Fabrication sans matériaux livrés."
			if bed.owner >= 0:
				if bed.owner in owners: return "Plusieurs lits attribués au même habitant."
				owners.append(bed.owner)
	if data.version >= 4:
		if not data.has("recovery") or not data.recovery is Array or data.recovery.size() > 4096: return "Matériaux à récupérer invalides."
		for pile in data.recovery:
			if not fields(pile, ["pos", "materials"]) or not valid_vector(pile.pos) or not fields(pile.materials, ["wood", "fiber"]): return "Tas de récupération incomplet."
			var upper_pile: bool = data.version >= 11 and number(pile.pos[0], 6 if data.version >= 13 else 9, 12) and number(pile.pos[2], -6, -3) and absf(pile.pos[1] - 2.0295) < .001
			if not upper_pile and (absf(pile.pos[0]) > (20 if data.version >= 15 else 10) or absf(pile.pos[2]) > (12.5 if data.version >= 15 else 8) or absf(pile.pos[1] + .0105) > .001): return "Tas de récupération hors de la carte."
			if not number(pile.materials.wood, 0, 6, true) or not number(pile.materials.fiber, 0, 5, true): return "Quantité à récupérer invalide."
			if data.version < 10 and pile.materials.wood + pile.materials.fiber == 0: return "Tas de récupération vide."
	if data.version >= 5:
		if not data.has("depots") or not data.depots is Array or data.depots.size() != depot_count: return "Dépôts incomplets."
		for i in range(depot_count):
			var depot = data.depots[i]
			if not fields(depot, ["stock", "capacity", "filters"]) or not fields(depot.stock, ["food", "wood", "fiber", "water"]): return "Dépôt incomplet."
			if not number(depot.capacity, 12, 400000000, true) or (i > 0 and depot.capacity != 12): return "Capacité de dépôt invalide."
			var used := 0
			for kind in ["food", "wood", "fiber", "water"]:
				if not number(depot.stock[kind], 0, 100000000, true): return "Stock local invalide."
				used += int(depot.stock[kind])
			if data.version >= 11 and i > 0:
				if not fields(depot, ["built", "active", "work", "materials"]) or not fields(depot.materials, ["wood", "fiber"]): return "Chantier de dépôt incomplet."
				if not depot.built is bool or not depot.active is bool or not number(depot.work, 0, 16): return "Chantier de dépôt invalide."
				if not number(depot.materials.wood, 0, 6, true) or not number(depot.materials.fiber, 0, 4, true): return "Matériaux de dépôt invalides."
				if depot.built != (depot.work == 16) or (not depot.built and used > 0): return "Stockage avant construction."
				if depot.work > 0 and (depot.materials.wood != 6 or depot.materials.fiber != 4): return "Dépôt construit sans matériaux."
				if not depot.active and (depot.built or depot.work > 0 or depot.materials.wood + depot.materials.fiber > 0): return "Dépôt annulé incohérent."
			if used > depot.capacity: return "Dépôt au-delà de sa capacité."
			if not depot.filters is Array or depot.filters.size() > 4: return "Filtres invalides."
			var seen: Array = []
			for kind in depot.filters:
				if not kind in ["food", "wood", "fiber", "water"] or kind in seen: return "Filtre inconnu ou dupliqué."
				seen.append(kind)
		if data.depots[0].stock != data.stock: return "Stock du refuge incohérent."
	if data.version >= 6:
		if not fields(data, ["torches"]) or not fields(data.torches, ["items", "orders"]): return "Équipement manquant."
		if (data.version >= 21 or data.torches.has("refill_target")) and (not data.torches.has("refill_target") or not number(data.torches.refill_target, 0, 8, true)): return "Objectif de lanternes invalide."
		if (data.version >= 24 or data.torches.has("craft_target")) and (not data.torches.has("craft_target") or not number(data.torches.craft_target, 0, 8, true)): return "Objectif de fabrication de lanternes invalide."
		if not data.torches.items is Array or data.torches.items.size() > 4096 or not data.torches.orders is Array or data.torches.orders.size() > 64: return "Équipement invalide."
		var locations: Array = []
		for building in data.buildings:
			if building.kind == "workshop": locations.append(building.pos)
		var active_orders: Array = []
		for site in data.torches.orders:
			if not fields(site, ["pos", "materials", "work"]) or not valid_vector(site.pos) or site.pos in active_orders: return "Atelier de torche invalide."
			var refill = site.get("refill", -1)
			if not number(refill, -1, data.torches.items.size() - 1, true): return "Lanterne à ravitailler invalide."
			if refill >= 0:
				if data.version < 20 or locations.is_empty(): return "Entretien sans atelier."
				var lamp = data.torches.items[int(refill)]
				if not fields(lamp, ["pos", "kind", "fuel"]) or lamp.kind != "lantern" or lamp.pos != site.pos or site.get("kind") != "lantern": return "Lanterne d’entretien incohérente."
			elif not site.pos in locations: return "Atelier de torche invalide."
			if data.version >= 7 and not site.has("kind"): return "Type d’éclairage manquant."
			var kind = site.get("kind", "torch")
			if not kind is String or not kind in ["torch", "lantern"] or (data.version < 7 and kind != "torch"): return "Type d’éclairage invalide."
			var wood := 4 if kind == "lantern" else 2
			var fiber := 3 if kind == "lantern" else 1
			var duration := 16.0 if kind == "lantern" else 8.0
			if refill >= 0:
				wood = 2
				fiber = 0
				duration = 8.0
			active_orders.append(site.pos)
			if not fields(site.materials, ["wood", "fiber"]) or not number(site.materials.wood, 0, wood, true) or not number(site.materials.fiber, 0, fiber, true) or not number(site.work, 0, duration - .000001): return "Fabrication d’éclairage invalide."
			if site.work > 0 and (site.materials.wood != wood or site.materials.fiber != fiber): return "Éclairage fabriqué sans matériaux."
		for item in data.torches.items:
			if not fields(item, ["pos", "fuel"]) or not valid_vector(item.pos): return "Éclairage incomplet."
			if data.version >= 7 and not item.has("kind"): return "Type d’éclairage manquant."
			var kind = item.get("kind", "torch")
			if not kind is String or not kind in ["torch", "lantern"] or (data.version < 7 and kind != "torch"): return "Type d’éclairage invalide."
			if not number(item.fuel, 0, 180 if kind == "lantern" else 90): return "Combustible invalide."
			var valid_place := Vector3(item.pos[0], item.pos[1], item.pos[2]).is_equal_approx(Vector3(-1.4, -.0105, 1.25))
			for pos in locations:
				if Vector3(item.pos[0], item.pos[1], item.pos[2]).is_equal_approx(Vector3(pos[0], -.0105, pos[2] + 1.15)): valid_place = true
			if not valid_place: return "Rangement de torche invalide."
	if data.version >= 8:
		if not fields(data, ["fissure"]) or not fields(data.fissure, ["discovered", "visited", "site"]): return "Passage incomplet."
		var passage: Dictionary = data.fissure
		if not passage.discovered is bool or not passage.visited is bool or not passage.site is Dictionary: return "Passage invalide."
		if not passage.site.is_empty():
			var site: Dictionary = passage.site
			if not passage.discovered or not fields(site, ["materials", "work", "built"]) or not fields(site.materials, ["wood", "fiber"]): return "Chantier de passage incomplet."
			if not site.built is bool or not number(site.work, 0, 24) or not number(site.materials.wood, 0, 6, true) or not number(site.materials.fiber, 0, 4, true): return "Chantier de passage invalide."
			if site.work > 0 and (site.materials.wood != 6 or site.materials.fiber != 4): return "Passage étayé sans matériaux."
			if site.built != (site.work == 24): return "Ouverture du passage incohérente."
		if passage.visited and (passage.site.is_empty() or not passage.site.built): return "Alcôve visitée sans passage ouvert."
	if data.version >= 9:
		var passage: Dictionary = data.fissure
		if not fields(passage, ["upgrade", "fiber", "known_fiber"]) or not passage.upgrade is Dictionary: return "Élargissement incomplet."
		if not number(passage.fiber, 0, 24, true) or not number(passage.known_fiber, -1, 24, true): return "Fibres distantes invalides."
		if passage.known_fiber != -1 and passage.known_fiber < passage.fiber: return "Connaissance des fibres incohérente."
		if not passage.upgrade.is_empty():
			var site: Dictionary = passage.upgrade
			if not passage.visited or not fields(site, ["materials", "work", "built"]) or not fields(site.materials, ["wood", "fiber"]): return "Élargissement sans reconnaissance ou matériaux."
			if not site.built is bool or not number(site.work, 0, 24) or not number(site.materials.wood, 0, 6, true) or not number(site.materials.fiber, 0, 4, true): return "Chantier d’élargissement invalide."
			if site.work > 0 and (site.materials.wood != 6 or site.materials.fiber != 4): return "Élargissement sans matériaux livrés."
			if site.built != (site.work == 24): return "Avancement d’élargissement incohérent."
		if passage.fiber < 24 and (passage.upgrade.is_empty() or not passage.upgrade.built): return "Récolte sans passage élargi."
	if data.version >= 10:
		var runtime_error := Live.validate(data)
		if not runtime_error.is_empty(): return runtime_error
	for assignment in data.assignments:
		if not number(assignment, -1, count - 1, true): return "Affectation invalide."
		if assignment >= 0 and not data.patches[int(assignment)].discovered: return "Affectation dans une zone inconnue."
	if not number(data.speed, 1, 3, true): return "Vitesse invalide."
	if not fields(data.clock, ["elapsed", "meal_timer", "suspicion", "hunger", "event_index"]): return "Horloge incomplète."
	for key in ["elapsed", "meal_timer", "suspicion", "hunger"]:
		if not number(data.clock[key], 0, 1000000000): return "Horloge invalide."
	if data.clock.meal_timer >= 18 or data.clock.suspicion >= 100 or data.clock.hunger >= 35: return "État de survie invalide."
	if not number(data.clock.event_index, -1, 10000000, true): return "Cycle invalide."
	if int(data.clock.event_index) != int(data.clock.elapsed / 100) and not (data.clock.elapsed == 0 and data.clock.event_index == -1): return "Cycle incohérent."
	if not fields(data.view, ["focus", "yaw", "zoom", "paths", "resident", "cutaway"]): return "Vue incomplète."
	if not valid_vector(data.view.focus) or not number(data.view.yaw, -1000000, 1000000) or not number(data.view.zoom, 5, 60 if data.version >= 15 else 34): return "Caméra invalide."
	if not data.view.paths is bool or not data.view.cutaway is bool or not number(data.view.resident, 0, data.assignments.size() - 1, true): return "Sélection invalide."
	return ""

static func read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {"ok": false, "error": "Aucune sauvegarde disponible."}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {"ok": false, "error": "Impossible de lire la sauvegarde."}
	if file.get_length() > 1048576:
		file.close()
		return {"ok": false, "error": "Fichier de sauvegarde trop volumineux."}
	var parser := JSON.new()
	var parsed := parser.parse(file.get_as_text())
	file.close()
	if parsed != OK: return {"ok": false, "error": "Sauvegarde illisible ou interrompue."}
	var problem := validate(parser.data)
	if not problem.is_empty(): return {"ok": false, "error": problem}
	return {"ok": true, "data": parser.data, "backup": false}

static func read_checkpoint(path: String) -> Dictionary:
	var result := read_file(path)
	if result.ok: return result
	var backup := read_file(path + ".bak")
	if backup.ok:
		backup.backup = true
		return backup
	return result

static func write_text(path: String, contents: String) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(contents)
	file.flush()
	var error := file.get_error()
	file.close()
	return error

static func write_checkpoint(path: String, data: Dictionary) -> String:
	var problem := validate(data)
	if not problem.is_empty(): return problem
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK: return "Impossible de créer le dossier de sauvegarde."
	var text := JSON.stringify(data, "\t", true, true)
	if write_text(path + ".tmp", text) != OK: return "Écriture impossible : la sauvegarde précédente est conservée."
	var verification := read_file(path + ".tmp")
	if not verification.ok: return "Vérification du nouveau fichier impossible : " + verification.error
	# Never replace the healthy backup with a corrupt primary save.
	if read_file(path).ok:
		if write_text(path + ".bak.tmp", FileAccess.get_file_as_string(path)) != OK: return "Impossible de conserver la copie de secours."
		if DirAccess.rename_absolute(path + ".bak.tmp", path + ".bak") != OK: return "Impossible de remplacer la copie de secours."
	if DirAccess.rename_absolute(path + ".tmp", path) != OK: return "Impossible de remplacer la sauvegarde précédente."
	return ""
