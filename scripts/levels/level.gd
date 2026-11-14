extends Node3D

# Echoes Beyond Earth - Base Level Controller
# Configures planet gravity, player state, and UI.

@export var planet_name: String = "Moon"
@export var level_gravity: float = 1.62

func _ready() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs:
		gs.current_planet = planet_name
	
	var player = get_tree().get_first_node_in_group("player")
	if player and "gravity" in player:
		player.gravity = level_gravity
	
	print("[Level] Loaded ", planet_name, " with gravity: ", level_gravity)
