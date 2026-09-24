extends RefCounted
## Plain, versioned data only. Transient jobs must settle before capture.
const VERSION := 3
const DEFAULT_PATH := "user://saves/colony_v1.json"
const KINDS := ["food", "food", "wood", "wood", "fiber", "fiber", "wood", "water"]

static func capture(game: Node) -> Dictionary:
	var buildings: Array = []
	for building in game.buildings:
		if building.kind != "heart": buildings.append({"kind": building.kind, "pos": vector(building.pos)})
	var patches: Array = []
	for patch in game.patches: patches.append({"kind": patch.kind, "amount": patch.amount, "discovered": patch.discovered})
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
		"stock": stocks, "patches": patches, "buildings": buildings,
		"assignments": assignments, "speed": game.speed,
		"needs": needs, "furnishings": game.sleeping.snapshot(),
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
	var count := 8 if data.version >= 3 else 7
	if not data.patches is Array or data.patches.size() != count: return "Carte de ressources incompatible."
	for i in range(count):
		var patch = data.patches[i]
		if not fields(patch, ["kind", "amount", "discovered"]): return "Gisement incomplet."
		if patch.kind != KINDS[i] or not number(patch.amount, 0, 100000000, true) or not patch.discovered is bool: return "Gisement invalide."
		if i < 6 and not patch.discovered: return "Gisement initial manquant."
		if i == 7 and not patch.discovered: return "Point d’eau initial manquant."
	if not data.buildings is Array or data.buildings.size() > 64: return "Bâtiments invalides."
	var shelters := 0
	var furnishings: Array = []
	for building in data.buildings:
		if not fields(building, ["kind", "pos"]) or not valid_vector(building.pos): return "Bâtiment incomplet."
		if not building.kind in ["shelter", "workshop", "bed", "private_bed"]: return "Type de bâtiment inconnu."
		if building.kind in ["bed", "private_bed"]: furnishings.append(building.kind)
		if building.pos[1] != 0 or not number(building.pos[0], -9, 9, true) or not number(building.pos[2], -6, 6, true): return "Emplacement de bâtiment invalide."
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
			if bed.owner >= 0:
				if bed.owner in owners: return "Plusieurs lits attribués au même habitant."
				owners.append(bed.owner)
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
	if not valid_vector(data.view.focus) or not number(data.view.yaw, -1000000, 1000000) or not number(data.view.zoom, 5, 34): return "Caméra invalide."
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
	var text := JSON.stringify(data, "\t")
	if write_text(path + ".tmp", text) != OK: return "Écriture impossible : la sauvegarde précédente est conservée."
	if not read_file(path + ".tmp").ok: return "Vérification du nouveau fichier impossible."
	# Never replace the healthy backup with a corrupt primary save.
	if read_file(path).ok:
		if write_text(path + ".bak.tmp", FileAccess.get_file_as_string(path)) != OK: return "Impossible de conserver la copie de secours."
		if DirAccess.rename_absolute(path + ".bak.tmp", path + ".bak") != OK: return "Impossible de remplacer la copie de secours."
	if DirAccess.rename_absolute(path + ".tmp", path) != OK: return "Impossible de remplacer la sauvegarde précédente."
	return ""
