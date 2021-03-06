# BuildingRules
extends Reference

static func can_automate_surface(player, planet, surface_building_tile):
	# TODO: might be easier to just check for existing research
	var researched = project_available(player, "automation", "Tech")
	var has_idlers = planet.population.idle >= 1
	var automated = false
	pass

static func can_automate_orbital(player, planet, orbital_building_tile):
	pass

# TODO: this only checks research, maybe rename it appropriately
static func project_available(player, project, type = null):
	# TODO: support other project types
	if type == null:
		type = "Surface"
	
	var definition
	if type == "Surface":
		definition = BuildingDefinitions.building_defs[project]
	elif type == "Orbital":
		definition = OrbitalDefinitions.orbital_defs[project]
	elif type == "Tech":
		definition = TechProjectDefinitions.project_defs[project]

	if definition == null:
		print("Definition for %s (%s) not found" % [project, type])
		return false
	if definition.requires_research != null:
		if player != null:
			return definition.requires_research in player.completed_research
		else:
			return false
	else:
		return true

static func get_projects_for_surface(planet, cell, building_tile):
	var player = planet.owner
	var cell_grid = planet.grid
	var building_grid = planet.buildings
	
	var projects = []
	var existing_building_type = null
	# TODO: include planet projects like party, scientific takeover etc
	# TODO: colony base can be automated
	# TODO: transport tubes can apparently be built everywhere
	var tiletype = cell.tiletype
	
	if building_tile.type != null:
		existing_building_type = building_tile.type.type
	
	for bdef_key in BuildingDefinitions.building_defs:
		# TODO: apply restrictions imposed by research progress
		# this is the building that wants to be built
		var building = BuildingDefinitions.building_defs[bdef_key]
		
		# collect all variables that define if this building is buildable on this tile by this player
		var allowed = true
		
		# check for research
		# TODO: use project_available
		if building.requires_research != null:
			if player != null:
				if not building.requires_research in player.completed_research:
					continue

		# short-circuit if it's not buildable
		if not building.buildable:
			continue

		# there are two concepts at play here that are similar but not equal
		# 1: there is no building on a tile
		# 2: there is a building on a tile
		# 2: if there is a building on a tile, there are restrictions depending on:
		#  - what you're trying to build
		#  - what's already there
		
		if existing_building_type == null:
			# no building on the tile
			# if there are building requirements for the bdef_key we're looking at, it can't be placed on empty
			# don't even bother with the tile below it
			if building.replaces != null:
				continue
			#if BuildingDefinitions.building_restriction.has(bdef_key):
			#	continue

			# TODO: idle population restriction only applies if there is no project running that uses pop, otherwise the new project is allowed to replace the old one
			# TODO: check if this can be moved outside because all buildings need pop
			# TODO: if building queues get implemented, queued buildings don't obey this restriction
			if planet.population.idle < building.used_pop_during_construction and planet.colony.project == null:
				continue

			# the color of the tile decides what can be built
			# special rule: orfa can build everything on black
			# special rule 2: nobody can build tubes or terraforming on normal squares
			# if there are any restrictions defined for this tile color (and there should be)
			if BuildingDefinitions.cell_restriction.has(tiletype):
				# get the restrictions
				var cell_restr = BuildingDefinitions.cell_restriction[tiletype]
				# this cell only allows certain buildings
				if cell_restr.has("allowed"):
					# TODO: orfa can build everything on black
					if not bdef_key in cell_restr["allowed"]:
						allowed = false
				# this cell excludes certain buildings
				elif cell_restr.has("restricted"):
					if bdef_key in cell_restr["restricted"]:
						allowed = false
			pass
		else:
			# there is a building on the tile
			# if the building is replaceable, unlike the colony base for example
			# there are restrictions as to what it can be replaced with
			# the very special case here are xeno ruins, which can only take a xeno dig, and only if they're next to a built tile already
			# the "normal" special cases are tubes, which can be replaced by terraforming (that deletes the tubes!)
			# ergo, if the building is replaceable, then the color underneath dictates by what
			# TODO: distinguish between active and inactive?
			var existing_building = BuildingDefinitions.building_defs[existing_building_type]

			if not existing_building.replaceable:
				allowed = false
			else:
				# if the building def we're looking at has a building restriction
				# it can only be placed on specific buildings
				if building.replaces != null:
					for rep in building.replaces:
						if allowed:
							allowed = allowed and rep == existing_building_type
						else:
							break
				
				if existing_building.replaced_by != null:
					for rep in existing_building.replaced_by:
						if allowed:
							allowed = allowed and rep == bdef_key
						else:
							break

				if allowed:
					# special case in which xeno ruins can only be used if directly connected to the rest of the base
					if existing_building_type == "xeno_ruins":
						var x = building_tile.tilemap_x
						var y = building_tile.tilemap_y

						# get the tiles around the one that was clicked
						var surrounding_tiles = Utils.get_tile_neighbors(x, y, building_grid)
						var can_build = false
						for t in surrounding_tiles:
							# surrounding_tiles[t] is supposed to be a building type
							if surrounding_tiles[t] != null:
								if not can_build and surrounding_tiles[t].type != null:
									can_build = true
							
						if not can_build:
							allowed = false
					else:
						# otherwise, the tile under the building decides what's okay
						# if there are any restrictions defined for this tile color (and there should be)
						if BuildingDefinitions.cell_restriction.has(tiletype):
							# get the restrictions
							var cell_restr = BuildingDefinitions.cell_restriction[tiletype]
							# this cell only allows certain buildings
							if cell_restr.has("allowed"):
								# TODO: orfa can build everything on black
								if not bdef_key in cell_restr["allowed"]:
									allowed = false
							# this cell excludes certain buildings
							elif cell_restr.has("restricted"):
								if bdef_key in cell_restr["restricted"]:
									allowed = false
		
		if allowed:
			projects.append(bdef_key)
	# TODO: sort by cell preference or whatever
	return projects

static func get_projects_for_orbit(planet, orbital_tile):
	var player = planet.owner
	var orbital_grid = planet.orbitals
	var projects = []

	var existing_orbital_type = null

	if orbital_tile.type != null:
		# an orbital exists on the chosen tile already
		existing_orbital_type = orbital_tile.type.type
	
	for odef_key in OrbitalDefinitions.orbital_defs:
		var orbital = OrbitalDefinitions.orbital_defs[odef_key]

		var allowed = true
		
		if orbital.buildable == false:
			continue

		if not project_available(player, odef_key, "Orbital"):
			continue
		# 4 things can be on a tile
		# a) nothing
		# b) a finished orbital building
		# c) an orbital in progress
		# d) a ship (friend or foe)

		if existing_orbital_type == null:
			# nothing is on the tile
			if planet.population.idle < orbital.used_pop_during_construction:
				continue
		else:
			pass

		if odef_key == "ship_placeholder":
			# ships need a shipyard on any other tile
			var has_shipyard = "shipyard" in planet.colony.unique_orbitals
			if not has_shipyard:
				continue
		
		if allowed:
			projects.append(odef_key)
	return projects