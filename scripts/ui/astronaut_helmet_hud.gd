extends CanvasLayer

# Echoes Beyond Earth - Apollo Spacesuit LEVA Visor HUD (Phase 4 updated)
# Recreates the astronaut's in-helmet telemetry display:
# - Suit pressure, oxygen reserve, PLSS battery, metabolic heart rate
# - Lunar gravity telemetry (1.62 m/s²)
# - Gait mode display: [WALK] vs [LUNAR LOPE]
# - Compass heading & pitch
# - Subtle gold LEVA visor contour vignette
# Phase 4: layer → UITokens.LAYER_TELEMETRY (5); SIM badges for static values

const UITokens = preload("res://scripts/ui/ui_tokens.gd")

@export var player_path: NodePath

var suit_pressure_label: Label
var consumables_label: Label
var heart_rate_label: Label
var gait_label: Label
var gravity_label: Label
var compass_label: Label
var view_mode_label: Label
var mission_clock_label: Label
var visor_overlay: Control

var _player_ref: CharacterBody3D
var _elapsed_sec: float = 0.0

func _ready() -> void:
	layer = UITokens.LAYER_TELEMETRY  # 5 — below world HUD overlays
	_build_hud_elements()
	call_deferred("_find_player")

func _find_player() -> void:
	if not player_path.is_empty():
		_player_ref = get_node_or_null(player_path) as CharacterBody3D
	if not _player_ref:
		_player_ref = get_tree().get_first_node_in_group("player") as CharacterBody3D

func _build_hud_elements() -> void:
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	
	# Visor curvature frame / vignette
	visor_overlay = Control.new()
	visor_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	visor_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(visor_overlay)
	
	# Top bar: Telemetry Readouts — offset below world HUD TopBar (offset_bottom=54)
	var top_panel = PanelContainer.new()
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 32
	top_panel.offset_right = -32
	top_panel.offset_top = 72
	top_panel.offset_bottom = 112
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Phase 4: style with token colours — translucent INK_900, no border
	var panel_sty := StyleBoxFlat.new()
	panel_sty.bg_color = Color(UITokens.INK_900, 0.78)
	panel_sty.border_width_left = 1
	panel_sty.border_width_bottom = 1
	panel_sty.border_color = UITokens.INK_600
	panel_sty.content_margin_left = 16.0
	panel_sty.content_margin_top = 4.0
	panel_sty.content_margin_right = 16.0
	panel_sty.content_margin_bottom = 4.0
	top_panel.add_theme_stylebox_override("panel", panel_sty)
	root.add_child(top_panel)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 28)
	top_panel.add_child(hbox)
	
	# SIM values (static): suit pressure, O2
	suit_pressure_label = _create_hud_item(hbox, "SUIT P [SIM]", "3.7 PSI", UITokens.SIGNAL_CYAN, true)
	consumables_label   = _create_hud_item(hbox, "PLSS O₂ [SIM]", "98.4%",  UITokens.SIGNAL_GREEN, true)
	# Live values: heart rate, gait, gravity, heading
	heart_rate_label = _create_hud_item(hbox, "HEART RATE", "82 BPM",           UITokens.SIGNAL_GOLD, false)
	gait_label       = _create_hud_item(hbox, "GAIT MODE", "LUNAR LOPE",        UITokens.PAPER_100,   false)
	gravity_label    = _create_hud_item(hbox, "GRAVITY",   "1.62 m/s²",         UITokens.SIGNAL_CYAN, false)
	compass_label    = _create_hud_item(hbox, "HEADING",   "045°",               UITokens.PAPER_300,   false)
	
	# Bottom bar: View mode & Mission Clock
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_hbox.offset_left = 36
	bottom_hbox.offset_right = -36
	bottom_hbox.offset_bottom = -50
	bottom_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom_hbox)
	
	view_mode_label = Label.new()
	view_mode_label.text = "VIEW: 3RD-PERSON CHASE [V]"
	view_mode_label.add_theme_color_override("font_color", UITokens.PAPER_500)
	view_mode_label.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
	bottom_hbox.add_child(view_mode_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_hbox.add_child(spacer)
	
	mission_clock_label = Label.new()
	mission_clock_label.text = "EVA MET [SIM]: 114:24:00"
	mission_clock_label.add_theme_color_override("font_color", UITokens.PAPER_500)
	mission_clock_label.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
	bottom_hbox.add_child(mission_clock_label)

func _create_hud_item(parent: HBoxContainer, title: String, val: String,
		col: Color, is_sim: bool) -> Label:
	var vb = VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(vb)
	
	var t = Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 12)
	t.add_theme_color_override("font_color",
		UITokens.PAPER_500 if not is_sim else Color(UITokens.PAPER_500, 0.7))
	vb.add_child(t)
	
	var v = Label.new()
	v.text = val
	v.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
	v.add_theme_color_override("font_color", col)
	vb.add_child(v)
	return v

func _process(delta: float) -> void:
	_elapsed_sec += delta
	var hr = int(_elapsed_sec / 3600.0) + 114
	var mn = int(fmod(_elapsed_sec, 3600.0) / 60.0) + 24
	var sc = int(fmod(_elapsed_sec, 60.0))
	mission_clock_label.text = "EVA MET [SIM]: %03d:%02d:%02d" % [hr, mn, sc]
	
	if not _player_ref:
		_find_player()
		return
	
	# Update gait mode
	var is_mars = false
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.current_planet == "Mars":
		is_mars = true
	elif _player_ref and "gravity" in _player_ref and _player_ref.gravity > 2.5:
		is_mars = true

	var is_loping = false
	if "is_loping_mode" in _player_ref:
		is_loping = _player_ref.is_loping_mode
	
	if is_mars:
		gait_label.text = "MARTIAN STRIDE" if is_loping else "SUIT WALK"
		if suit_pressure_label and suit_pressure_label.get_parent():
			var title_lbl = suit_pressure_label.get_parent().get_child(0) as Label
			if title_lbl:
				title_lbl.text = "ATMOSPHERE [SIM]"
			suit_pressure_label.text = "6.1 hPa (95.3% CO₂)"
	else:
		gait_label.text = "LUNAR LOPE" if is_loping else "SUIT WALK"
	gait_label.add_theme_color_override("font_color",
		UITokens.SIGNAL_GREEN if is_loping else UITokens.PAPER_100)
	
	# Update heart rate from exertion
	var exertion = 0.0
	if "exertion_level" in _player_ref:
		exertion = _player_ref.exertion_level
	var bpm = int(lerp(76.0, 138.0, exertion))
	heart_rate_label.text = "%d BPM" % bpm
	heart_rate_label.add_theme_color_override("font_color",
		UITokens.SIGNAL_RED if bpm >= 115 else UITokens.SIGNAL_GOLD)
	
	# Update heading and pitch
	if "camera_pivot" in _player_ref and _player_ref.camera_pivot:
		var yaw_deg = int(fmod(rad_to_deg(_player_ref.camera_pivot.rotation.y) + 360.0, 360.0))
		compass_label.text = "%03d°" % yaw_deg
	
	# Update gravity readout dynamically
	if "gravity" in _player_ref and gravity_label:
		var g_val = _player_ref.gravity
		var g_ratio = g_val / 9.80665
		gravity_label.text = "%.2f m/s² (%.3f g)" % [g_val, g_ratio]
	
	# Update view mode label
	# B9 FIX: removed duplicate assignment and "MINION EVA" dead string
	var is_first_person = false
	if "is_first_person" in _player_ref:
		is_first_person = _player_ref.is_first_person
	view_mode_label.text = "VIEW: 1ST-PERSON EVA VISOR [V]" if is_first_person else "VIEW: 3RD-PERSON CHASE [V]"
