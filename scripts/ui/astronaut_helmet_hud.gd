extends CanvasLayer

# Echoes Beyond Earth - NASA Apollo Spacesuit LEVA Visor & Telemetry HUD
# Information-dense spacecraft dashboard inspired by lunar mission instrumentation:
# - Circular gauges for Suit Pressure (PSI/kPa) and PLSS Oxygen Reserve (%)
# - Real-time scrolling dynamic ECG Heart Rate waveform graph linked to exertion_level
# - Segmented progress bars for PLSS Battery / Power
# - Aerospace compass heading visualizer with cardinal bearings & camera pitch
# - Lunar gravity (1.62 m/s²) & gait telemetry (SUIT WALK vs LUNAR LOPE)
# - Environmental vacuum telemetry, mission elapsed time (MET), system status
# - Subtle gold LEVA visor contour and corner framing ticks

@export var player_path: NodePath

var _player_ref: CharacterBody3D
var _elapsed_sec: float = 0.0

# UI Controls
var visor_overlay: Control
var top_panel: PanelContainer
var left_instrument_panel: Control
var right_instrument_panel: Control
var bottom_bar: HBoxContainer

# Dynamic Readout Labels
var suit_pressure_label: Label
var consumables_label: Label
var heart_rate_label: Label
var gait_label: Label
var gravity_label: Label
var compass_label: Label
var view_mode_label: Label
var mission_clock_label: Label
var co2_label: Label

# Waveform & Animated Telemetry Data
var _ecg_points: Array[float] = []
var _ecg_scroll_phase: float = 0.0
var _current_bpm: int = 78
var _current_heading: float = 45.0
var _current_pitch: float = 0.0
var _exertion: float = 0.0
var _battery_pct: float = 94.0

const PAL_BG = Color(0.0196, 0.0353, 0.0510, 0.86)
const PAL_CYAN = Color(0.0, 0.898, 1.0, 1.0)
const PAL_CYAN_DIM = Color(0.0, 0.898, 1.0, 0.35)
const PAL_TURQUOISE = Color(0.0, 0.749, 0.647, 1.0)
const PAL_AMBER = Color(1.0, 0.616, 0.196, 1.0)
const PAL_CRITICAL = Color(1.0, 0.271, 0.271, 1.0)
const PAL_GREEN = Color(0.224, 0.898, 0.549, 1.0)
const PAL_WHITE = Color(0.898, 0.949, 0.961, 1.0)
const PAL_GREY = Color(0.467, 0.565, 0.616, 1.0)

func _ready() -> void:
	layer = 8
	_init_ecg_buffer()
	_build_hud_elements()
	call_deferred("_find_player")

func _init_ecg_buffer() -> void:
	_ecg_points.clear()
	for i in range(60):
		_ecg_points.append(0.0)

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
	
	# Fallback/compatibility label references
	suit_pressure_label = Label.new()
	suit_pressure_label.text = "3.7 PSI (25.5 kPa)"
	suit_pressure_label.visible = false
	root.add_child(suit_pressure_label)
	
	consumables_label = Label.new()
	consumables_label.text = "98.4%"
	consumables_label.visible = false
	root.add_child(consumables_label)
	
	heart_rate_label = Label.new()
	heart_rate_label.text = "78 BPM"
	heart_rate_label.visible = false
	root.add_child(heart_rate_label)
	
	compass_label = Label.new()
	compass_label.text = "045° NNE"
	compass_label.visible = false
	root.add_child(compass_label)
	
	# 1. Visor curvature frame / vignette with custom drawing
	visor_overlay = Control.new()
	visor_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	visor_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visor_overlay.draw.connect(_on_draw_visor_overlay)
	root.add_child(visor_overlay)
	
	# 2. Top Telemetry Header Bar
	top_panel = PanelContainer.new()
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 28
	top_panel.offset_right = -28
	top_panel.offset_top = 58 # Positioned cleanly beneath global TopBar
	top_panel.offset_bottom = 92
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var sb_top = AerospaceTheme.create_technical_badge_style(PAL_CYAN_DIM, PAL_BG)
	top_panel.add_theme_stylebox_override("panel", sb_top)
	root.add_child(top_panel)
	
	var top_hbox = HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hbox.add_theme_constant_override("separation", 24)
	top_panel.add_child(top_hbox)
	
	_create_header_badge(top_hbox, "COMM", "UP-LINK NOMINAL", PAL_GREEN)
	gait_label = _create_header_badge(top_hbox, "GAIT MODE", "SUIT WALK [Shift/C]", PAL_CYAN)
	gravity_label = _create_header_badge(top_hbox, "GRAVITY", "1.62 m/s² (0.166 g)", PAL_TURQUOISE)
	mission_clock_label = _create_header_badge(top_hbox, "EVA MET", "114:24:00", PAL_AMBER)
	_create_header_badge(top_hbox, "CO2 SCRUBBER", "PRIMARY CANISTER", PAL_WHITE)
	
	# 3. Left Instrumentation Cluster (Suit Pressure, PLSS O2, ECG Waveform, Battery)
	left_instrument_panel = Control.new()
	left_instrument_panel.offset_left = 28
	left_instrument_panel.offset_top = 104
	left_instrument_panel.custom_minimum_size = Vector2(250, 310)
	left_instrument_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_instrument_panel.draw.connect(_on_draw_left_instruments)
	root.add_child(left_instrument_panel)
	
	# 4. Right Instrumentation Cluster (Compass, Atmosphere, Equipment Status)
	right_instrument_panel = Control.new()
	right_instrument_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right_instrument_panel.offset_left = -268
	right_instrument_panel.offset_right = -28
	right_instrument_panel.offset_top = 104
	right_instrument_panel.custom_minimum_size = Vector2(240, 210)
	right_instrument_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	right_instrument_panel.draw.connect(_on_draw_right_instruments)
	root.add_child(right_instrument_panel)
	
	# 5. Bottom Navigation & Control Banner
	bottom_bar = HBoxContainer.new()
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.offset_left = 32
	bottom_bar.offset_right = -32
	bottom_bar.offset_bottom = -14
	bottom_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom_bar)
	
	view_mode_label = Label.new()
	view_mode_label.text = "EVA PERSPECTIVE: 3RD-PERSON ASTRONAUT [Scroll to Zoom]"
	view_mode_label.add_theme_color_override("font_color", PAL_CYAN)
	view_mode_label.add_theme_font_size_override("font_size", 12)
	bottom_bar.add_child(view_mode_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_bar.add_child(spacer)
	
	var hints_label = Label.new()
	hints_label.text = "[W/A/S/D] EVA Walk  •  [SPACE] Lunar Jump  •  [Shift/C] Toggle Lope  •  [E] Excavate  •  [F] Sample Compendium"
	hints_label.add_theme_color_override("font_color", PAL_GREY)
	hints_label.add_theme_font_size_override("font_size", 12)
	bottom_bar.add_child(hints_label)

func _create_header_badge(parent: HBoxContainer, title: String, val: String, col: Color) -> Label:
	var vb = HBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(vb)
	
	var t = Label.new()
	t.text = title + ":"
	t.add_theme_font_size_override("font_size", 11)
	t.add_theme_color_override("font_color", PAL_GREY)
	vb.add_child(t)
	
	var v = Label.new()
	v.text = val
	v.add_theme_font_size_override("font_size", 11)
	v.add_theme_color_override("font_color", col)
	vb.add_child(v)
	return v

func _process(delta: float) -> void:
	_elapsed_sec += delta
	var hr = int(_elapsed_sec / 3600.0) + 114
	var mn = int(fmod(_elapsed_sec, 3600.0) / 60.0) + 24
	var sc = int(fmod(_elapsed_sec, 60.0))
	if mission_clock_label:
		mission_clock_label.text = "%03d:%02d:%02d" % [hr, mn, sc]
	
	if not _player_ref:
		_find_player()
		return
	
	# Exertion & BPM
	_exertion = _player_ref.exertion_level if "exertion_level" in _player_ref else 0.0
	_current_bpm = int(lerp(76.0, 138.0, _exertion))
	
	# Gait mode
	var is_loping = _player_ref.is_loping_mode if "is_loping_mode" in _player_ref else false
	if gait_label:
		gait_label.text = "LUNAR LOPE [Shift/C]" if is_loping else "SUIT WALK [Shift/C]"
		gait_label.add_theme_color_override("font_color", PAL_GREEN if is_loping else PAL_CYAN)
	
	# Heading & Pitch
	if "camera_pivot" in _player_ref and _player_ref.camera_pivot:
		_current_heading = fmod(rad_to_deg(_player_ref.camera_pivot.rotation.y) + 360.0, 360.0)
		_current_pitch = rad_to_deg(_player_ref.camera_pivot.rotation.x)
	
	# Gravity
	if "gravity" in _player_ref and gravity_label:
		var g_val = _player_ref.gravity
		var g_ratio = g_val / 9.80665
		gravity_label.text = "%.2f m/s² (%.3f g)" % [g_val, g_ratio]
	
	# Update ECG buffer
	var freq = lerp(1.2, 2.8, _exertion)
	_ecg_scroll_phase = fmod(_ecg_scroll_phase + delta * freq * 6.0, TAU)
	
	# Generate realistic P-QRS-T electrocardiogram waveform shape
	var raw_val = 0.0
	var phase_norm = _ecg_scroll_phase / TAU
	if phase_norm > 0.10 and phase_norm < 0.18:
		# P wave
		raw_val = sin((phase_norm - 0.10) / 0.08 * PI) * 0.22
	elif phase_norm >= 0.22 and phase_norm < 0.25:
		# Q dip
		raw_val = -0.28
	elif phase_norm >= 0.25 and phase_norm < 0.30:
		# R sharp peak
		raw_val = 1.0
	elif phase_norm >= 0.30 and phase_norm < 0.34:
		# S dip
		raw_val = -0.42
	elif phase_norm > 0.42 and phase_norm < 0.58:
		# T wave
		raw_val = sin((phase_norm - 0.42) / 0.16 * PI) * 0.35
	
	_ecg_points.pop_front()
	_ecg_points.append(raw_val)
	
	# Trigger redraws
	if left_instrument_panel: left_instrument_panel.queue_redraw()
	if right_instrument_panel: right_instrument_panel.queue_redraw()

# ---- DRAWING: Visor Reticle & Framing Ticks ----
func _on_draw_visor_overlay() -> void:
	var w = visor_overlay.size.x
	var h = visor_overlay.size.y
	if w < 100 or h < 100:
		return
	
	# Subtle corner framing brackets
	var bracket_len = 24.0
	var pad = 18.0
	var col = Color(PAL_CYAN.r, PAL_CYAN.g, PAL_CYAN.b, 0.28)
	
	# Top-left
	visor_overlay.draw_line(Vector2(pad, pad), Vector2(pad + bracket_len, pad), col, 1.2)
	visor_overlay.draw_line(Vector2(pad, pad), Vector2(pad, pad + bracket_len), col, 1.2)
	# Top-right
	visor_overlay.draw_line(Vector2(w - pad, pad), Vector2(w - pad - bracket_len, pad), col, 1.2)
	visor_overlay.draw_line(Vector2(w - pad, pad), Vector2(w - pad, pad + bracket_len), col, 1.2)
	# Bottom-left
	visor_overlay.draw_line(Vector2(pad, h - pad), Vector2(pad + bracket_len, h - pad), col, 1.2)
	visor_overlay.draw_line(Vector2(pad, h - pad), Vector2(pad, h - pad - bracket_len), col, 1.2)
	# Bottom-right
	visor_overlay.draw_line(Vector2(w - pad, h - pad), Vector2(w - pad - bracket_len, h - pad), col, 1.2)
	visor_overlay.draw_line(Vector2(w - pad, h - pad), Vector2(w - pad, h - pad - bracket_len), col, 1.2)

# ---- DRAWING: Left Instrument Cluster (Gauges, ECG Waveform, Battery) ----
func _on_draw_left_instruments() -> void:
	var font = ThemeDB.fallback_font
	
	# Background panel
	var rect = Rect2(Vector2.ZERO, left_instrument_panel.size)
	left_instrument_panel.draw_rect(rect, PAL_BG)
	_draw_technical_frame(left_instrument_panel, rect, PAL_CYAN_DIM, PAL_TURQUOISE)
	
	# Header title
	if font:
		left_instrument_panel.draw_string(font, Vector2(12, 18), "PLSS BIOMETRIC & LIFE SUPPORT", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, PAL_CYAN)
	
	# Circular Gauge 1: SUIT PRESSURE (3.7 PSI / 25.5 kPa)
	var g1_center = Vector2(58, 68)
	var g_radius = 28.0
	_draw_circular_gauge(left_instrument_panel, g1_center, g_radius, 3.7 / 5.0, "3.7 PSI", "SUIT P", PAL_CYAN, PAL_GREEN)
	
	# Circular Gauge 2: PLSS OXYGEN (98.4%)
	var g2_center = Vector2(150, 68)
	_draw_circular_gauge(left_instrument_panel, g2_center, g_radius, 0.984, "98.4%", "O2 RES", PAL_TURQUOISE, PAL_CYAN)
	
	# Divider line
	left_instrument_panel.draw_line(Vector2(10, 112), Vector2(rect.size.x - 10, 112), PAL_CYAN_DIM, 1.0)
	
	# ECG Waveform Graph (Heart Rate)
	var ecg_bpm_col = PAL_GREEN if _current_bpm < 115 else PAL_AMBER
	if font:
		left_instrument_panel.draw_string(font, Vector2(12, 128), "HEART RATE: %d BPM" % _current_bpm, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ecg_bpm_col)
		var ecg_state = "NOMINAL" if _current_bpm < 115 else "HIGH EXERTION"
		left_instrument_panel.draw_string(font, Vector2(rect.size.x - 80, 128), ecg_state, HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, ecg_bpm_col)
	
	# ECG Graph Area
	var graph_origin = Vector2(12, 136)
	var graph_w = rect.size.x - 24.0
	var graph_h = 56.0
	left_instrument_panel.draw_rect(Rect2(graph_origin, Vector2(graph_w, graph_h)), Color(0.01, 0.02, 0.03, 0.75))
	left_instrument_panel.draw_rect(Rect2(graph_origin, Vector2(graph_w, graph_h)), PAL_CYAN_DIM, false, 1.0)
	
	# Horizontal centerline
	var mid_y = graph_origin.y + graph_h * 0.5
	left_instrument_panel.draw_line(Vector2(graph_origin.x, mid_y), Vector2(graph_origin.x + graph_w, mid_y), Color(PAL_CYAN.r, PAL_CYAN.g, PAL_CYAN.b, 0.15), 1.0)
	
	# Plot ECG waveform line
	var n_pts = _ecg_points.size()
	if n_pts > 1:
		var step_x = graph_w / float(n_pts - 1)
		var prev_pt = Vector2(graph_origin.x, mid_y - _ecg_points[0] * (graph_h * 0.42))
		for i in range(1, n_pts):
			var cur_pt = Vector2(graph_origin.x + i * step_x, mid_y - _ecg_points[i] * (graph_h * 0.42))
			var pt_alpha = float(i) / float(n_pts)
			var line_col = Color(ecg_bpm_col.r, ecg_bpm_col.g, ecg_bpm_col.b, pt_alpha * 0.95)
			left_instrument_panel.draw_line(prev_pt, cur_pt, line_col, 1.4)
			prev_pt = cur_pt
	
	# Divider line
	left_instrument_panel.draw_line(Vector2(10, 206), Vector2(rect.size.x - 10, 206), PAL_CYAN_DIM, 1.0)
	
	# Segmented Battery Indicator
	if font:
		left_instrument_panel.draw_string(font, Vector2(12, 222), "PLSS SUIT BATTERY: 94%", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, PAL_CYAN)
	
	var bar_x = 12.0
	var bar_y = 230.0
	var total_w = rect.size.x - 24.0
	var n_segments = 10
	var seg_w = (total_w - float(n_segments - 1) * 3.0) / float(n_segments)
	var active_segs = int(round(0.94 * n_segments))
	
	for s in range(n_segments):
		var sx = bar_x + float(s) * (seg_w + 3.0)
		var s_rect = Rect2(Vector2(sx, bar_y), Vector2(seg_w, 14.0))
		if s < active_segs:
			left_instrument_panel.draw_rect(s_rect, PAL_CYAN)
		else:
			left_instrument_panel.draw_rect(s_rect, Color(PAL_CYAN.r, PAL_CYAN.g, PAL_CYAN.b, 0.15))
		left_instrument_panel.draw_rect(s_rect, PAL_CYAN_DIM, false, 1.0)
	
	# Telemetry Status summary
	if font:
		left_instrument_panel.draw_string(font, Vector2(12, 262), "SUIT VENTILATION: NOMINAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, PAL_TURQUOISE)
		left_instrument_panel.draw_string(font, Vector2(12, 278), "PRIMARY FEEDWATER: 88.5%", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, PAL_WHITE)
		left_instrument_panel.draw_string(font, Vector2(12, 294), "CO2 PARTIAL PRESS: 0.2 mmHg", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, PAL_GREEN)

# ---- DRAWING: Right Instrument Cluster (Compass Heading & Environment) ----
func _on_draw_right_instruments() -> void:
	var font = ThemeDB.fallback_font
	var rect = Rect2(Vector2.ZERO, right_instrument_panel.size)
	
	right_instrument_panel.draw_rect(rect, PAL_BG)
	_draw_technical_frame(right_instrument_panel, rect, PAL_CYAN_DIM, PAL_TURQUOISE)
	
	if font:
		right_instrument_panel.draw_string(font, Vector2(12, 18), "NAVIGATION & HORIZON TELEMETRY", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, PAL_CYAN)
	
	# Compass Bearing Tape
	var tape_y = 32.0
	var tape_w = rect.size.x - 24.0
	var tape_h = 36.0
	var tape_rect = Rect2(Vector2(12, tape_y), Vector2(tape_w, tape_h))
	right_instrument_panel.draw_rect(tape_rect, Color(0.01, 0.02, 0.03, 0.8))
	right_instrument_panel.draw_rect(tape_rect, PAL_CYAN_DIM, false, 1.0)
	
	# Ticks on compass tape
	var center_x = 12.0 + tape_w * 0.5
	var deg_step = 15.0
	var px_per_deg = 1.2
	
	for d in range(-60, 61, 15):
		var target_deg = fmod(_current_heading + float(d) + 360.0, 360.0)
		var tick_x = center_x + float(d) * px_per_deg
		if tick_x >= 14.0 and tick_x <= 10.0 + tape_w:
			var is_cardinal = (int(round(target_deg)) % 90 == 0)
			var tick_h = 14.0 if is_cardinal else 7.0
			var tick_col = PAL_AMBER if is_cardinal else PAL_CYAN_DIM
			right_instrument_panel.draw_line(Vector2(tick_x, tape_y + tape_h - tick_h), Vector2(tick_x, tape_y + tape_h), tick_col, 1.2)
			
			if is_cardinal and font:
				var c_label = "N" if target_deg < 45 or target_deg > 315 else ("E" if target_deg < 135 else ("S" if target_deg < 225 else "W"))
				right_instrument_panel.draw_string(font, Vector2(tick_x - 4, tape_y + 14), c_label, HORIZONTAL_ALIGNMENT_CENTER, -1, 9, PAL_AMBER)
	
	# Center pointer tick
	right_instrument_panel.draw_line(Vector2(center_x, tape_y), Vector2(center_x, tape_y + 10), PAL_CYAN, 2.0)
	
	# Heading readout
	if font:
		var heading_str = "HEADING: %03d°" % int(round(_current_heading))
		right_instrument_panel.draw_string(font, Vector2(12, 86), heading_str, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, PAL_CYAN)
		right_instrument_panel.draw_string(font, Vector2(rect.size.x - 90, 86), "PITCH: %+02d°" % int(round(_current_pitch)), HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, PAL_WHITE)
	
	# Divider line
	right_instrument_panel.draw_line(Vector2(10, 98), Vector2(rect.size.x - 10, 98), PAL_CYAN_DIM, 1.0)
	
	# Environmental telemetry
	if font:
		right_instrument_panel.draw_string(font, Vector2(12, 116), "SURFACE ENVIRONMENT:", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, PAL_TURQUOISE)
		right_instrument_panel.draw_string(font, Vector2(12, 134), "VACUUM: < 10⁻¹⁰ Pa (NOMINAL)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, PAL_WHITE)
		right_instrument_panel.draw_string(font, Vector2(12, 150), "SURFACE TEMP: -23°C (SHADOW)", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, PAL_WHITE)
		right_instrument_panel.draw_string(font, Vector2(12, 166), "RADIATION DOSIMETER: NORMAL", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, PAL_GREEN)
		right_instrument_panel.draw_string(font, Vector2(12, 182), "SUIT THERMAL LOOP: 18.2°C", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, PAL_CYAN)

# Helper: Circular Gauge with arc and label
func _draw_circular_gauge(canvas: Control, center: Vector2, radius: float, fraction: float, val_text: String, title: String, arc_col: Color, val_col: Color) -> void:
	var font = ThemeDB.fallback_font
	var start_angle = deg_to_rad(135.0)
	var end_angle = deg_to_rad(405.0)
	var total_span = end_angle - start_angle
	
	# Background track arc
	canvas.draw_arc(center, radius, start_angle, end_angle, 32, Color(PAL_CYAN.r, PAL_CYAN.g, PAL_CYAN.b, 0.2), 2.0)
	
	# Active fill arc
	var fill_span = total_span * clampf(fraction, 0.0, 1.0)
	canvas.draw_arc(center, radius, start_angle, start_angle + fill_span, 32, arc_col, 2.8)
	
	# Outer subtle tick marks
	for i in range(5):
		var a = start_angle + total_span * (float(i) / 4.0)
		var p1 = center + Vector2(cos(a), sin(a)) * (radius + 2.0)
		var p2 = center + Vector2(cos(a), sin(a)) * (radius + 5.0)
		canvas.draw_line(p1, p2, PAL_CYAN_DIM, 1.0)
	
	if font:
		canvas.draw_string(font, Vector2(center.x - 24, center.y + 2), val_text, HORIZONTAL_ALIGNMENT_CENTER, 48, 11, val_col)
		canvas.draw_string(font, Vector2(center.x - 24, center.y + 16), title, HORIZONTAL_ALIGNMENT_CENTER, 48, 9, PAL_GREY)

# Helper: Technical corner brackets around a panel
func _draw_technical_frame(canvas: Control, r: Rect2, border_col: Color, bracket_col: Color) -> void:
	canvas.draw_rect(r, border_col, false, 1.0)
	var b_len = 10.0
	# Top-left
	canvas.draw_line(r.position, r.position + Vector2(b_len, 0), bracket_col, 1.5)
	canvas.draw_line(r.position, r.position + Vector2(0, b_len), bracket_col, 1.5)
	# Top-right
	var tr = Vector2(r.end.x, r.position.y)
	canvas.draw_line(tr, tr - Vector2(b_len, 0), bracket_col, 1.5)
	canvas.draw_line(tr, tr + Vector2(0, b_len), bracket_col, 1.5)
	# Bottom-left
	var bl = Vector2(r.position.x, r.end.y)
	canvas.draw_line(bl, bl + Vector2(b_len, 0), bracket_col, 1.5)
	canvas.draw_line(bl, bl - Vector2(0, b_len), bracket_col, 1.5)
	# Bottom-right
	canvas.draw_line(r.end, r.end - Vector2(b_len, 0), bracket_col, 1.5)
	canvas.draw_line(r.end, r.end - Vector2(0, b_len), bracket_col, 1.5)
