extends Control

# Futuristic Sci-Fi Holographic Tactical Minimap
# Features:
# - Transparent glass circular radar dial with cyan/orange neon vector lines
# - Real-time rotating holographic radar sweep
# - Player directional chevron & cardinal crosshairs (N, S, E, W)
# - Real-time tactical artifact blips with toroidal distance support
# - Proximity targeting lock-on bracket

@export var radar_range: float = 65.0 # Max radius in meters
@export var sweep_speed: float = 2.4 # Radians per second

var sweep_angle: float = 0.0
var _player_ref: CharacterBody3D = null
var _scanner_ref: Node = null
var _artifacts: Array = []

const COLOR_CYAN = Color(0.0, 0.95, 1.0, 0.95)
const COLOR_CYAN_DIM = Color(0.0, 0.75, 0.95, 0.35)
const COLOR_CYAN_FAINT = Color(0.0, 0.65, 0.85, 0.18)
const COLOR_ORANGE = Color(1.0, 0.60, 0.08, 0.95)
const COLOR_ORANGE_DIM = Color(1.0, 0.55, 0.05, 0.45)
const COLOR_GREEN_LOCK = Color(0.2, 1.0, 0.4, 0.95)

func _ready() -> void:
	custom_minimum_size = Vector2(160, 160)
	call_deferred("_cache_references")

func _cache_references() -> void:
	_player_ref = get_tree().get_first_node_in_group("player") as CharacterBody3D
	_scanner_ref = get_tree().get_first_node_in_group("scanner")
	_artifacts = get_tree().get_nodes_in_group("artifacts")

func _process(delta: float) -> void:
	sweep_angle = fmod(sweep_angle + sweep_speed * delta, TAU)
	queue_redraw()

func _draw() -> void:
	var center = size * 0.5
	var radius = minf(center.x, center.y) - 6.0
	
	if radius <= 10.0:
		return
	
	# 1. Dark transparent glass base circle
	draw_circle(center, radius, Color(0.02, 0.05, 0.09, 0.65))
	
	# 2. Concentric Neon Cyan Range Rings (25m, 50m, 75m)
	draw_arc(center, radius * 0.33, 0.0, TAU, 32, COLOR_CYAN_FAINT, 1.0)
	draw_arc(center, radius * 0.66, 0.0, TAU, 48, COLOR_CYAN_DIM, 1.0)
	draw_arc(center, radius, 0.0, TAU, 64, COLOR_CYAN, 1.5)
	
	# Outer subtle neon cyan glow ring
	draw_arc(center, radius + 1.5, 0.0, TAU, 64, Color(0.0, 0.95, 1.0, 0.35), 1.0)
	
	# 3. Tactical Cardinal Crosshairs
	draw_line(Vector2(center.x, center.y - radius), Vector2(center.x, center.y + radius), COLOR_CYAN_FAINT, 1.0)
	draw_line(Vector2(center.x - radius, center.y), Vector2(center.x + radius, center.y), COLOR_CYAN_FAINT, 1.0)
	
	# Cardinal Labels: N (Orange), S, E, W
	var font = ThemeDB.fallback_font
	if font:
		draw_string(font, Vector2(center.x - 4, center.y - radius + 12), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 10, COLOR_ORANGE)
		draw_string(font, Vector2(center.x - 4, center.y + radius - 4), "S", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, COLOR_CYAN_DIM)
		draw_string(font, Vector2(center.x + radius - 12, center.y + 3), "E", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, COLOR_CYAN_DIM)
		draw_string(font, Vector2(center.x - radius + 4, center.y + 3), "W", HORIZONTAL_ALIGNMENT_CENTER, -1, 9, COLOR_CYAN_DIM)
	
	# 4. Rotating Holographic Sweep Beam with fade trail
	var sweep_segments = 12
	var trail_arc = deg_to_rad(45.0)
	for i in range(sweep_segments):
		var frac = float(i) / float(sweep_segments)
		var a = sweep_angle - (1.0 - frac) * trail_arc
		var alpha = frac * 0.28
		var beam_col = Color(COLOR_CYAN.r, COLOR_CYAN.g, COLOR_CYAN.b, alpha)
		var p1 = center
		var p2 = center + Vector2(cos(a), sin(a)) * radius
		draw_line(p1, p2, beam_col, 1.2)
	
	# Leading sweep vector line
	var lead_p = center + Vector2(cos(sweep_angle), sin(sweep_angle)) * radius
	draw_line(center, lead_p, COLOR_CYAN, 1.8)
	
	if not _player_ref:
		_cache_references()
		return
	
	var player_pos = _player_ref.global_position
	var player_rot_y = 0.0
	if "visuals" in _player_ref and _player_ref.visuals:
		player_rot_y = _player_ref.visuals.rotation.y
	elif "camera_pivot" in _player_ref and _player_ref.camera_pivot:
		player_rot_y = _player_ref.camera_pivot.rotation.y
	
	# 5. Artifact Tactical Blips
	var terrain = get_tree().get_first_node_in_group("terrain")
	var world_size: float = 180.0
	if terrain and "terrain_size" in terrain:
		world_size = terrain.terrain_size
	var half_world: float = world_size * 0.5
	
	var game_state = get_node_or_null("/root/GameState")
	
	for art in _artifacts:
		if not is_instance_valid(art) or not art.has_method("get_world_position"):
			continue
		
		var art_id = art.get_artifact_id() if art.has_method("get_artifact_id") else ""
		var is_recovered = game_state and game_state.is_artifact_recovered(art_id)
		if is_recovered:
			continue
		
		var art_pos = art.get_world_position()
		
		# Toroidal relative offset
		var dx = art_pos.x - player_pos.x
		if world_size > 0.0:
			if dx > half_world: dx -= world_size
			elif dx < -half_world: dx += world_size
		
		var dz = art_pos.z - player_pos.z
		if world_size > 0.0:
			if dz > half_world: dz -= world_size
			elif dz < -half_world: dz += world_size
		
		var dist = sqrt(dx * dx + dz * dz)
		if dist > radar_range * 1.2:
			continue
		
		# Map world coordinates (X=East, Z=South) to 2D Minimap coordinates
		var norm_dist = clampf(dist / radar_range, 0.0, 0.95)
		var angle = atan2(dz, dx)
		var blip_pos = center + Vector2(cos(angle), sin(angle)) * (norm_dist * radius)
		
		# Tactical Blip: Glowing Orange Diamond
		var blip_size = 3.5
		if dist <= 4.0:
			# Locked on close proximity: Glowing Green pulsing diamond & reticle
			var pulse = 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.008)
			_draw_diamond(blip_pos, blip_size * 1.3, COLOR_GREEN_LOCK)
			_draw_target_bracket(blip_pos, 8.0 * pulse, COLOR_GREEN_LOCK)
		else:
			_draw_diamond(blip_pos, blip_size, COLOR_ORANGE)
			# Small subtle glow
			draw_circle(blip_pos, blip_size * 1.8, Color(COLOR_ORANGE.r, COLOR_ORANGE.g, COLOR_ORANGE.b, 0.25))
	
	# 6. Player Directional Marker (Center Cyan Chevron)
	_draw_player_chevron(center, player_rot_y)

func _draw_diamond(pos: Vector2, sz: float, col: Color) -> void:
	var pts = PackedVector2Array([
		pos + Vector2(0, -sz),
		pos + Vector2(sz, 0),
		pos + Vector2(0, sz),
		pos + Vector2(-sz, 0)
	])
	draw_colored_polygon(pts, col)
	draw_polyline(pts, Color(1, 1, 1, 0.8), 1.0)

func _draw_target_bracket(pos: Vector2, sz: float, col: Color) -> void:
	var arm = sz * 0.4
	# Top-left
	draw_line(pos + Vector2(-sz, -sz), pos + Vector2(-sz + arm, -sz), col, 1.2)
	draw_line(pos + Vector2(-sz, -sz), pos + Vector2(-sz, -sz + arm), col, 1.2)
	# Top-right
	draw_line(pos + Vector2(sz, -sz), pos + Vector2(sz - arm, -sz), col, 1.2)
	draw_line(pos + Vector2(sz, -sz), pos + Vector2(sz, -sz + arm), col, 1.2)
	# Bottom-left
	draw_line(pos + Vector2(-sz, sz), pos + Vector2(-sz + arm, sz), col, 1.2)
	draw_line(pos + Vector2(-sz, sz), pos + Vector2(-sz, sz - arm), col, 1.2)
	# Bottom-right
	draw_line(pos + Vector2(sz, sz), pos + Vector2(sz - arm, sz), col, 1.2)
	draw_line(pos + Vector2(sz, sz), pos + Vector2(sz, sz - arm), col, 1.2)

func _draw_player_chevron(center: Vector2, yaw: float) -> void:
	# Direction vector in 2D minimap space
	# World forward is +Z or -Z depending on camera; in our coordinate system:
	# atan2(dx, dz) where dx is East (X), dz is South (Z).
	var dir = Vector2(sin(yaw), cos(yaw))
	var right = Vector2(-dir.y, dir.x)
	
	var tip = center + dir * 6.0
	var left_wing = center - dir * 4.0 - right * 4.0
	var right_wing = center - dir * 4.0 + right * 4.0
	var indent = center - dir * 1.5
	
	var pts = PackedVector2Array([tip, right_wing, indent, left_wing])
	draw_colored_polygon(pts, COLOR_CYAN)
	draw_polyline(pts, Color(1, 1, 1, 0.9), 1.2)
	draw_circle(center, 1.8, Color(1, 1, 1, 1))
