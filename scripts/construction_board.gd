extends RefCounted
## Read-only projection: opening the board never claims or advances a task.

static func entries(g: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var sites: Array = g.construction.sites()
	for i in range(sites.size()):
		var site: Dictionary = sites[i]
		if site.built or not site.get("active", true): continue
		var title := "Lit %d" % (g.sleeping.beds.find(site) + 1)
		var panel := "beds"
		var selection := -1
		if site.get("room_site", false):
			panel = "rooms"
			for r in range(g.rooms.rooms.size()):
				if site in g.rooms.rooms[r].parts: selection = r
			title = "Chambre %d · %s" % [selection + 1, g.rooms.TITLES[site.phase]]
		elif site.get("fixed_site", false):
			panel = "fixed_light"
			title = "Combustible du brasero" if site.fuel_site else "Brasero de la passerelle"
		elif site.get("depot_site", false):
			panel = "depots"
			selection = g.depots.sites.find(site)
			title = "Dépôt %d" % selection
		elif site.get("fissure_site", false):
			panel = "fissure"
			title = "Élargissement du passage" if site == g.fissure.upgrade else "Aménagement de la fissure"
		elif site.get("torch_site", false):
			panel = "torches"
			if site.get("refill", -1) >= 0:
				panel = "lantern_service"
				title = "Entretien · Lanterne %d" % (site.refill + 1)
			else:
				title = "Fabrication · %s %d" % ["Lanterne" if site.kind == "lantern" else "Torche", g.torches.orders.find(site) + 1]
		var detail: String = g.construction.status(site) + "\n" + g.construction.quantities(site)
		var owner: int = site.builder if site.builder >= 0 else site.hauler
		if owner >= 0:
			detail += "\nH%d · %s" % [owner + 1, g.workers[owner].delivery.description()]
		else:
			var kind := "build" if g.construction.supplied(site) else "transport"
			if not site.get("fuel_site", false) or kind == "transport":
				if not permitted(g, kind): detail += "\n%s : aucun habitant autorisé (priorité 0)." % g.priorities.NAMES[kind]
		result.append({"key": "site:%d" % i, "title": title, "detail": detail, "panel": panel, "selection": selection, "pos": site.pos})
	for i in range(g.construction.recovery.size()):
		var pile: Dictionary = g.construction.recovery[i]
		var detail := "Bois %d · Fibres %d à récupérer" % [pile.materials.wood, pile.materials.fiber]
		if pile.hauler >= 0: detail += "\nH%d · %s" % [pile.hauler + 1, g.workers[pile.hauler].delivery.description()]
		elif not permitted(g, "transport"): detail += "\nTransport : aucun habitant autorisé (priorité 0)."
		else: detail += "\nAttend un porteur et une place au dépôt."
		result.append({"key": "recovery:%d" % i, "title": "Matériaux récupérables", "detail": detail, "panel": "depots", "selection": -1, "pos": pile.pos})
	return result

static func permitted(g: Node, kind: String) -> bool:
	for id in range(g.workers.size()):
		if g.priorities.value(id, kind) > 0: return true
	return false

static func summary(g: Node, count: int) -> String:
	var text := "%d chantier(s) ou tas à suivre." % count if count > 0 else "Aucun chantier actif ni matériau à récupérer."
	if g.ended: text += "\nColonie arrêtée."
	elif g.hiding: text += "\nRappel actif : les habitants se mettent à l’abri."
	elif g.paused: text += "\nSimulation en pause · Espace pour reprendre."
	return text
