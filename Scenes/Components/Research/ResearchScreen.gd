extends "res://Scripts/Model/Screen.gd"

onready var tree = get_node("ResearchTree/Research3D/Viewport/research_root")

# label for active research, hides when previewing others
onready var current_title = get_node("CurrentResearch/Current")

# pics for active research
onready var active_research = get_node("CurrentResearch/ActiveResearch")
onready var research_ring = get_node("CurrentResearch/Ring")

# labels for previewed or active research
onready var research_title = get_node("CurrentResearch/Title")
onready var research_time = get_node("CurrentResearch/Time")

# title bar elements
onready var flag = get_node("Title/Flag/FlagIcon")
onready var race = get_node("Title/Text/RaceKnowledge")

# TODO: get a factory to do this
var ResearchProject = preload("res://Scripts/Model/ResearchProject.gd")

func _ready():
	tree.connect("research_selected", self, "_on_research_selected")
	tree.connect("research_enter", self, "_on_research_enter")
	tree.connect("research_exit", self, "_on_research_exit")

	pass

# setup for the entire screen
func show_research(player):
	# TODO: update UI elements
	tree.show_research(player)
	display_current_research(player)
	pass

# hides the right side preview elements
func clear_research():
	current_title.hide()
	active_research.hide()
	research_ring.hide()
	research_title.hide()
	research_time.hide()
	pass
	
func show_default():
	active_research.show()
	research_ring.show()
	research_title.show()
	research_time.show()

# displays research under the mouse
func preview_research(player, research):
	show_default()
	current_title.hide()
	active_research.set_texture(TextureHandler.get_research_icon(research))
	research_title.set_text(research)
	pass

# displays active research
func display_current_research(player):
	if player.research_project:
		show_default()
		current_title.show()
		active_research.set_texture(TextureHandler.get_research_icon(player.research_project.research))
		research_title.set_text(player.research_project.research)
	pass


func display_research(player, research, active = false):
	pass

func _on_research_selected(player, research):
	# TODO: this probably should be in a ResearchHandler
	if not research in player.completed_research:
		var resDef = ResearchDefinitions.research_defs[research]
		var proj = ResearchProject.new()
		proj.research = research
		proj.remaining_research = resDef.cost
		proj.initial_cost = resDef.cost
		player.start_research(proj)
		display_current_research(player)
	pass
	
func _on_research_enter(player, research):
	preview_research(player, research)
	pass
	
func _on_research_exit(player, research):
	if player.research_project:
		display_current_research(player)
	else:
		clear_research()
	pass