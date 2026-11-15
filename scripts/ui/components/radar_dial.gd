class_name RadarDial
extends Control

## Echoes Beyond Earth — RadarDial (merge phase P3)
## North-up proximity radar that lives inside ScannerInstrument (bottom-right).
## Behaviour is a faithful port of the retired integrated1 radar script (tactical_minimap.gd, see git history); only the look changed:
##   - range 65 m, X = east, Z = south, player chevron + view cone
##   - blips for every UNRECOVERED node in group "artifacts", culled beyond 1.15 x range
##   - toroidal wrap using `terrain_size` of group "terrain" (fallback 180 m) for the spherical Moon
##   - lock-on at <= 4 m is the only proximity "pulse" (the scanner's audio ping is disabled on purpose)
## Mystery rule: blips are anonymous. No names, no categories, nothing is highlighted but the lock.
## Style rules (MASTER.md): colours from UITokens only; shape carries meaning (hollow diamond = signal,
## filled diamond + brackets = lock); sweep/pulse are the one allowed decorative-motion exception and
## freeze when SettingsStore.motion_scale() is 0.

const DIAL_SIZE := 144      ## px; shrunk from 168 to meet the HUD area budget (plan 6.4)
const LOCK_RANGE := 4.0
const CULL_FACTOR := 1.15
const MAX_NORM := 0.94
const FALLBACK_WORLD_SIZE := 180.0
const REQUERY_SECONDS := 1.0
const MONO_FONT_PATH := "res://assets/fonts/IBMPlexMono-Medium.ttf"

@export var radar_range: float = 65.0
@export var sweep_speed: float = 2.4   ## radians per second (before motion scale)

var sweep_angle: float = 0.0
var locked_on: bool = false

var _enabled: bool = true
var _player: Node3D = null
var _artifacts: Array = []
var _blips: Array = []            ## [{dx, dz, dist, locked}] in metres, already wrapped
var _player_pos: Vector3 = Vector3.ZERO
var _player_yaw: float = 0.0
var _requery_left: float = 0.0
var _pulse_t: float = 0.0
var _font: Font = null


func _ready() -> void:
	custom_minimum_size = Vector2(DIAL_SIZE, DIAL_SIZE)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = load(MONO_FONT_PATH) as Font
	if _font == null:
		_font = ThemeDB.fallback_font
	refresh_artifacts()


## Public API ----------------------------------------------------------------------------

## Re-query the "artifacts" group. Mars spawns spacecraft at runtime, so this also runs ~1 Hz.
func refresh_artifacts() -> void:
	if not is_inside_tree():
		return
	_artifacts = get_tree().get_nodes_in_group("artifacts")
	_requery_left = REQUERY_SECONDS


func get_blip_count() -> int:
	return _blips.size()


func get_blips() -> Array:
	return _blips


func get_player_position() -> Vector3:
	return _player_pos


func set_enabled(v: bool) -> void:
	_enabled = v
	visible = v
	set_process(v)


## Recompute blips from the current player / artifact state (also called every frame).
func update_blips() -> void:
	_resolve_player()
	_blips.clear()
	locked_on = false
	if _player == null:
		return
	_player_pos = _player.global_position
	_player_yaw = _read_yaw(_player)
	var world_size: float = _world_size()
	var gs: Node = get_node_or_null("/root/GameState")
	for art in _artifacts:
		if not is_instance_valid(art) or not art.has_method("get_world_position"):
			continue
		var art_id: String = String(art.get_artifact_id()) if art.has_method("get_artifact_id") else ""
		if art_id != "" and gs != null and gs.is_artifact_recovered(art_id):
			continue
		var off: Vector2 = relative_offset(art.get_world_position(), _player_pos, world_size)
		var dist: float = off.length()
		if dist > radar_range * CULL_FACTOR:
			continue
		var is_lock: bool = dist <= LOCK_RANGE
		if is_lock:
			locked_on = true
		_blips.append({"dx": off.x, "dz": off.y, "dist": dist, "locked": is_lock})


## Offset (east, south) from the player to an artifact, wrapped across +-half-world.
static func relative_offset(art_pos: Vector3, player_pos: Vector3, world_size: float) -> Vector2:
	var dx: float = art_pos.x - player_pos.x
	var dz: float = art_pos.z - player_pos.z
	if world_size > 0.0:
		var half: float = world_size * 0.5
		if dx > half:
			dx -= world_size
		elif dx < -half:
			dx += world_size
		if dz > half:
			dz -= world_size
		elif dz < -half:
			dz += world_size
	return Vector2(dx, dz)


## Where a blip sits on the dial: distance is clamped to MAX_NORM of the radius, same as the old minimap.
static func blip_dial_offset(dx: float, dz: float, radar_range_m: float, radius_px: float) -> Vector2:
	var norm: float = clampf(sqrt(dx * dx + dz * dz) / radar_range_m, 0.0, MAX_NORM)
	var a: float = atan2(dz, dx)
	return Vector2(cos(a), sin(a)) * (norm * radius_px)


## Process --------------------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _enabled or not is_visible_in_tree():
		return
	var motion: float = SettingsStore.motion_scale()
	if motion > 0.0:
		sweep_angle = fmod(sweep_angle + sweep_speed * delta * motion, TAU)
		_pulse_t += delta * motion
	_requery_left -= delta
	if _requery_left <= 0.0:
		refresh_artifacts()
	update_blips()
	queue_redraw()


func _resolve_player() -> void:
	if _player == null or not is_instance_valid(_player):
		if is_inside_tree():
			_player = get_tree().get_first_node_in_group("player") as Node3D


func _world_size() -> float:
	if is_inside_tree():
		var terrain: Node = get_tree().get_first_node_in_group("terrain")
		if terrain != null and "terrain_size" in terrain:
			return float(terrain.terrain_size)
	return FALLBACK_WORLD_SIZE


func _read_yaw(p: Node) -> float:
	if "visuals" in p and p.visuals != null:
		return p.visuals.rotation.y
	if "camera_pivot" in p and p.camera_pivot != null:
		return p.camera_pivot.rotation.y
	return 0.0


## Drawing ---------------------------------------------------------------------------------

func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(c.x, c.y) - 6.0
	if r <= 10.0:
		return

	# Plate + range rings (inner two are decorative, the outer one is the 65 m limit)
	draw_circle(c, r, Color(UITokens.INK_900, 0.82))
	draw_arc(c, r * 0.33, 0.0, TAU, 32, UITokens.INK_600, 1.0)
	draw_arc(c, r * 0.66, 0.0, TAU, 48, UITokens.INK_600, 1.0)
	draw_arc(c, r, 0.0, TAU, 64, UITokens.PAPER_500, 1.0)

	# Crosshair
	draw_line(c + Vector2(0, -r), c + Vector2(0, r), UITokens.INK_600, 1.0)
	draw_line(c + Vector2(-r, 0), c + Vector2(r, 0), UITokens.INK_600, 1.0)

	# Ticks every 30 degrees; cardinals longer; the N tick is the single gold accent
	for i in 12:
		var a: float = float(i) * (TAU / 12.0) - PI * 0.5
		var cardinal: bool = i % 3 == 0
		var tlen: float = 6.0 if cardinal else 3.0
		var col: Color = UITokens.SIGNAL_GOLD if i == 0 else UITokens.PAPER_500
		var d := Vector2(cos(a), sin(a))
		draw_line(c + d * (r - tlen), c + d * r, col, 1.0)

	# Cardinal labels (12 px = minimum caption size) and the range tag
	var fs: int = UITokens.TEXT_CAPTION
	_label("N", c + Vector2(0, -r + 20), UITokens.SIGNAL_GOLD, fs, true)
	_label("S", c + Vector2(0, r - 8), UITokens.PAPER_300, fs, true)
	_label("E", c + Vector2(r - 12, 4), UITokens.PAPER_300, fs, true)
	_label("W", c + Vector2(-r + 12, 4), UITokens.PAPER_300, fs, true)
	var tag: Vector2 = c + Vector2(r * 0.62, -r * 0.62)
	_label("%d M" % int(radar_range), tag, UITokens.PAPER_300, fs, true)

	# Sweep: trail <= 0.20 alpha + a 1.5 px lead line (frozen at reduced motion)
	var segs: int = 14
	var trail: float = deg_to_rad(45.0)
	for i in segs:
		var f: float = float(i) / float(segs)
		var ang: float = sweep_angle - (1.0 - f) * trail
		draw_line(c, c + Vector2(cos(ang), sin(ang)) * r, Color(UITokens.SIGNAL_CYAN, f * 0.20), 1.0)
	draw_line(c, c + Vector2(cos(sweep_angle), sin(sweep_angle)) * r, Color(UITokens.SIGNAL_CYAN, 0.55), 1.5)

	# Blips
	var pulse: float = 1.0
	if SettingsStore.motion_scale() > 0.0:
		pulse = 0.85 + 0.15 * sin(_pulse_t * 8.0)
	for b in _blips:
		var p: Vector2 = c + blip_dial_offset(b["dx"], b["dz"], radar_range, r)
		if b["locked"]:
			_diamond(p, 5.0, UITokens.SIGNAL_GOLD, true)
			_brackets(p, 9.0 * pulse, UITokens.SIGNAL_GOLD)
		else:
			_diamond(p, 3.5, UITokens.SIGNAL_GOLD, false)

	_chevron(c, _player_yaw)


func _label(text: String, center: Vector2, col: Color, fs: int, centered: bool) -> void:
	if _font == null:
		return
	var w: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pos: Vector2 = center - Vector2(w * 0.5 if centered else 0.0, 0.0)
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _diamond(pos: Vector2, s: float, col: Color, filled: bool) -> void:
	var pts := PackedVector2Array([pos + Vector2(0, -s), pos + Vector2(s, 0), pos + Vector2(0, s), pos + Vector2(-s, 0)])
	if filled:
		draw_colored_polygon(pts, col)
		pts.append(pts[0])
		draw_polyline(pts, UITokens.INK_900, 1.0)
	else:
		pts.append(pts[0])
		draw_polyline(pts, col, 1.5)


func _brackets(pos: Vector2, s: float, col: Color) -> void:
	var arm: float = s * 0.45
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			var corner: Vector2 = pos + Vector2(sx * s, sy * s)
			draw_line(corner, corner - Vector2(sx * arm, 0.0), col, 1.5)
			draw_line(corner, corner - Vector2(0.0, sy * arm), col, 1.5)


func _chevron(c: Vector2, yaw: float) -> void:
	var dir := Vector2(sin(yaw), cos(yaw))
	var right := Vector2(-dir.y, dir.x)
	draw_colored_polygon(PackedVector2Array([c, c + dir * 16.0 - right * 7.0, c + dir * 16.0 + right * 7.0]),
		Color(UITokens.PAPER_100, 0.12))
	var pts := PackedVector2Array([c + dir * 6.5, c - dir * 4.0 + right * 4.0, c - dir * 1.5, c - dir * 4.0 - right * 4.0])
	draw_colored_polygon(pts, UITokens.PAPER_100)
	pts.append(pts[0])
	draw_polyline(pts, UITokens.INK_900, 1.0)
