extends Reference

# creates a sensible colony based on a planet grid
var BuildingTile = preload("res://Scripts/Model/BuildingTile.gd")
var Planetmap = preload("res://Scripts/Planetmap.gd")
var Colony = preload("res://Scripts/Model/Colony.gd")

var buildings = {}

var colony_base_neighbor_scores = ["black", "blue", "white", "green", "red"]
var colony_base_tile_scores = ["blue", "white", "green", "red", "black"]
var colony_plans = ["initial", "industry", "research", "debug"]

var colony_plan = {
	"initial": {
		"colony_base": 1,
		"factory": 12,
		"agriplot": 4
	}
}

func initialize_colony(player, planet, home = false):
	# TODO: use predefined sizes and types for home planets
	planet.owner = player
	var colony = Colony.new()
	colony.owner = player
	# TODO: allow the player to rename planets (on colonize and later)
	colony.name = planet.planet_name
	colony.home = home
	# associate the objects
	colony.planet = planet
	planet.colony = colony
	# TODO: disallow duplicate names or use another dictionary key system
	player.colonies[colony.name] = colony
	
	# give the planet a random colony base
	# TODO: allow picking the colony position
	var colony_tile = generate_colony(planet, "initial")
	var building_tile = planet.buildings[colony_tile.x][colony_tile.y]
	building_tile.set("colony_base")
	planet.population.alive = 2
	#building_tile.tilemap_x = colony_tile.x
	#building_tile.tilemap_y = colony_tile.y
	colony.refresh()
	pass

func generate_colony(planet, plan):
	# TODO: move count_cells to a static func somewhere
	var cell_count = Planetmap.new().count_cells(planet)
	
	# init empty building grid
	# TODO: this probably is not good in this place
	if planet.buildings.size() == 0:
		for x in range(mapdefs.planet_max_grid):
			planet.buildings.append([])
			for y in range(mapdefs.planet_max_grid):
				var building_tile = BuildingTile.new()
				planet.buildings[x].append(building_tile)
	
	var colony_coords = pick_colony_spot(planet, cell_count)

	return colony_coords
	pass
	
func pick_colony_spot(planet, cell_count):
	var best_tile = null
	var best_score = null
	var all_tiles = []
	
	# neighbors can just be a list of colors, technically, to be able to easily check if e.g. red > green for a given tile
	var neighbors = {}
	
	# there can be multiple tiles with the same score, at that point it's nicer to pick a random one
	var tiles_by_score = {
		0: []
	}
	
	# if the best tile by score on a cornucopia is a blue surrounded by reds, it's bad because it wastes the blue (no RP from colony base)
	# if there are only black and white tiles, prefer black
	
	## what even is the best tile?
	# on any given layout
	# if xeno ruins exist, their neighbors are preferable (even if black)
	# if black >= usable, prefer black
	# if red >= green, prefer green?
	
	# scoring?
	# greatest sum = most valuable tile?
	# worst tile with best neighbors = most valuable tile?
	
	# TODO: scoring can be used in other features as well: govorom special ability can pick the least useful planet and upgrade it
	# FIXME: this still puts the colony onto blue squares on small planets
	
	for x in range(mapdefs.planet_max_grid):
		for y in range(mapdefs.planet_max_grid):
			var tile = planet.grid[x][y]
			# get current tile type
			var tile_type = tile.get_tile_type()

			# null tiles aren't buildable, so they are not interesting
			if tile_type != null:
				# get neighbor tile types
				neighbors = Utils.get_tile_neighbors(x, y, planet.grid)
				
				var score = _get_tile_score(tile, neighbors)
				tile.score = score
				if not tiles_by_score.has(score):
					tiles_by_score[score] = []
				tiles_by_score[score].append(Vector2(x,y))
				
				if best_score == null or best_score < score:
					best_score = score
					best_tile = Vector2(x, y)
	
	var sorted_tiles = tiles_by_score.keys()
	sorted_tiles.sort()
	
	var highest_score = sorted_tiles.back()
	var best_tiles = tiles_by_score[highest_score]
	if best_tiles.size() > 1:
		var random_highest = randi() % best_tiles.size()
		best_tile = best_tiles[random_highest]
	else:
		best_tile = best_tiles.front()
	return best_tile
	pass
	
func _get_tile_score(tile, neighbors):
	var sum = 0
	var tile_index = colony_base_tile_scores.find(tile.get_tile_type())
	# TODO: this is dirty, but it works.. still dirty
	if tile.get_tile_type() == "blue":
		tile_index = -50
	sum += tile_index
	for n in neighbors:
		var n_type = null
		if neighbors[n] != null:
			n_type = neighbors[n].get_tile_type()
		var n_index = colony_base_neighbor_scores.find(n_type)
		sum += n_index
	return sum
	pass