extends Node3D

# Echoes Beyond Earth - Base Level Controller
# Configures planet gravity, player state, and UI.

@export var planet_name: String = "Moon"
@export var level_gravity: float = 3.24

func _ready() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.current_planet = planet_name
	
	var player = get_tree().get_first_node_in_group("player")
	if player and "gravity" in player:
		if player.has_method("update_gravity"):
			player.update_gravity(level_gravity)
		else:
			player.gravity = level_gravity
	
	var dust = get_tree().get_first_node_in_group("ballistic_dust")
	if dust and dust.has_method("set_gravity"):
		dust.set_gravity(level_gravity)
	
	print("[Level] Loaded ", planet_name, " with gravity: ", level_gravity)
