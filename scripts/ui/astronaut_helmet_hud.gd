extends CanvasLayer

# Echoes Beyond Earth - Suit telemetry (Phase 4)
# Bottom-left zone of the world HUD (top-left, top-right and bottom-right belong to WorldHud).
# LIVE values: heart rate (from exertion), gait, gravity, heading, view mode.
# SIM values (invented, labelled with a SIM badge): suit pressure / atmosphere, O2, EVA clock.
# Public label fields are read by the regression tests; keep their names.
# Layer: UITokens.LAYER_TELEMETRY (5).

@export var player_path: NodePath

var suit_pressure_label: Label
var consumables_label: Label
var heart_rate_label: Label
var gait_label: Label
var gravity_label: Label
var compass_label: Label
var view_mode_label: Label
var mission_clock_label: Label

var _suit_title: Label
var _hr_title: Label
var _player_ref: CharacterBody3D
var _elapsed_sec: float = 0.0


func _ready() -> void:
	layer = UITokens.LAYER_TELEMETRY
	_build_hud_elements()
	call_deferred("_find_player")


func _find_player() -> void:
	if not player_path.is_empty():
		_player_ref = get_node_or_null(player_path) as CharacterBody3D
	if not _player_ref:
		_player_ref = get_tree().get_first_node_in_group("player") as CharacterBody3D


func _build_hud_elements() -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UITokens.theme()
	add_child(root)

	var panel := HudPanel.new()
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", UITokens.SP_2)
	panel.add_child(col)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_theme_constant_override("h_separation", UITokens.SP_6)
	grid.add_theme_constant_override("v_separation", UITokens.SP_2)
	col.add_child(grid)

	# Row 1: SIM, SIM, LIVE.   Row 2: LIVE x3.
	var c1: Array = _cell(grid, "SUIT PRESSURE", "3.7 PSI", UITokens.SIGNAL_CYAN, true)
	_suit_title = c1[0]
	suit_pressure_label = c1[1]
	consumables_label = _cell(grid, "PLSS O₂", "98.4%", UITokens.SIGNAL_CYAN, true)[1]
	var c3: Array = _cell(grid, "HEART RATE", "82 BPM", UITokens.SIGNAL_GOLD, false)
	_hr_title = c3[0]
	heart_rate_label = c3[1]
	gait_label = _cell(grid, "GAIT", "LUNAR LOPE", UITokens.PAPER_100, false)[1]
	gravity_label = _cell(grid, "GRAVITY", "1.62 m/s²", UITokens.SIGNAL_CYAN, false)[1]
	compass_label = _cell(grid, "HEADING", "045°", UITokens.PAPER_100, false)[1]

	var rule := ColorRect.new()
	rule.color = UITokens.INK_600
	rule.custom_minimum_size = Vector2(0, 1)
	col.add_child(rule)

	# Footer: view mode (with its key-cap) and the simulated EVA clock.
	var foot := HBoxContainer.new()
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.add_theme_constant_override("separation", UITokens.SP_2)
	col.add_child(foot)
	var cap := KeyCap.new()
	cap.action_name = "view_toggle"
	foot.add_child(cap)
	view_mode_label = Label.new()
	view_mode_label.text = "VIEW: 3RD-PERSON CHASE"
	view_mode_label.theme_type_variation = &"CaptionLabel"
	view_mode_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view_mode_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.add_child(view_mode_label)
	mission_clock_label = Label.new()
	mission_clock_label.text = "EVA MET 114:24:00"
	mission_clock_label.theme_type_variation = &"CaptionLabel"
	mission_clock_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	foot.add_child(mission_clock_label)
	foot.add_child(Badge.make(Badge.Kind.SIM))

	root.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, WorldHud.MARGIN)
	panel.grow_vertical = Control.GROW_DIRECTION_BEGIN


## One telemetry cell: caption title over a mono value (+ SIM badge when invented).
## Returns [title_label, value_label].
func _cell(parent: GridContainer, title: String, val: String, col: Color, is_sim: bool) -> Array:
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 2)
	parent.add_child(vb)

	var t := Label.new()
	t.text = title
	t.theme_type_variation = &"CaptionLabel"
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(t)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UITokens.SP_1)
	vb.add_child(row)
	var v := Label.new()
	v.text = val
	v.theme_type_variation = &"StatLabel"
	v.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
	v.add_theme_color_override("font_color", col)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(v)
	if is_sim:
		row.add_child(Badge.make(Badge.Kind.SIM))
	return [t, v]


func _process(delta: float) -> void:
	_elapsed_sec += delta
	var hr: int = int(_elapsed_sec / 3600.0) + 114
	var mn: int = int(fmod(_elapsed_sec, 3600.0) / 60.0) + 24
	var sc: int = int(fmod(_elapsed_sec, 60.0))
	mission_clock_label.text = "EVA MET %03d:%02d:%02d" % [hr, mn, sc]

	if not _player_ref:
		_find_player()
		return

	var is_mars: bool = false
	var gs: Node = get_node_or_null("/root/GameState")
	if gs and gs.current_planet == "Mars":
		is_mars = true
	elif "gravity" in _player_ref and _player_ref.gravity > 2.5:
		is_mars = true

	var is_loping: bool = false
	if "is_loping_mode" in _player_ref:
		is_loping = _player_ref.is_loping_mode

	if is_mars:
		gait_label.text = "MARTIAN STRIDE" if is_loping else "SUIT WALK"
		_suit_title.text = "ATMOSPHERE"
		suit_pressure_label.text = "6.1 hPa"
	else:
		gait_label.text = "LUNAR LOPE" if is_loping else "SUIT WALK"

	# Heart rate from exertion. High is stated in words, not only coloured.
	var exertion: float = 0.0
	if "exertion_level" in _player_ref:
		exertion = _player_ref.exertion_level
	var bpm: int = int(lerp(76.0, 138.0, exertion))
	heart_rate_label.text = "%d BPM" % bpm
	var high: bool = bpm >= 115
	_hr_title.text = "HEART RATE · HIGH" if high else "HEART RATE"
	heart_rate_label.add_theme_color_override("font_color", UITokens.SIGNAL_RED if high else UITokens.SIGNAL_GOLD)

	if "camera_pivot" in _player_ref and _player_ref.camera_pivot:
		var yaw_deg: int = int(fmod(rad_to_deg(_player_ref.camera_pivot.rotation.y) + 360.0, 360.0))
		compass_label.text = "%03d°" % yaw_deg

	if "gravity" in _player_ref and gravity_label:
		gravity_label.text = "%.2f m/s²" % float(_player_ref.gravity)

	var fp: bool = false
	if "is_first_person" in _player_ref:
		fp = _player_ref.is_first_person
	view_mode_label.text = "VIEW: 1ST-PERSON VISOR" if fp else "VIEW: 3RD-PERSON CHASE"
