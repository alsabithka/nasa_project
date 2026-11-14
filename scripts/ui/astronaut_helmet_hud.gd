extends CanvasLayer

# Echoes Beyond Earth - Apollo Spacesuit LEVA Visor HUD
# Recreates the astronaut's in-helmet telemetry display with futuristic sci-fi holographic style:
# - Transparent glass panels with neon cyan and orange vector lines
# - Suit pressure, oxygen reserve, PLSS battery, metabolic heart rate
# - Lunar gravity telemetry (1.62 m/s²)
# - Gait mode display: [WALK] vs [LUNAR LOPE]
# - Compass heading & pitch
# - Clean typography and dark space backdrop elements

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
	layer = 8
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
	
	# Top bar: Telemetry Readouts (Transparent glass panel with cyan/orange styling)
	var top_panel = PanelContainer.new()
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 32
	top_panel.offset_right = -32
	top_panel.offset_top = 62 # Positioned cleanly beneath global TopBar
	top_panel.offset_bottom = 104
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var glass_tex = load("res://textures/ui/sci_fi_glass_panel.png")
	if glass_tex:
		var sb = StyleBoxTexture.new()
		sb.texture = glass_tex
		sb.texture_margin_left = 12
		sb.texture_margin_top = 12
		sb.texture_margin_right = 12
		sb.texture_margin_bottom = 12
		sb.content_margin_left = 16
		sb.content_margin_top = 4
		sb.content_margin_right = 16
		sb.content_margin_bottom = 4
		top_panel.add_theme_stylebox_override("panel", sb)
	
	root.add_child(top_panel)
	
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 24)
	top_panel.add_child(hbox)
	
	suit_pressure_label = _create_hud_item(hbox, "SUIT PRESSURE", "3.7 PSI (25.5 kPa)", Color(0.0, 0.95, 1.0))
	consumables_label = _create_hud_item(hbox, "PLSS OXYGEN", "98.4%", Color(0.2, 1.0, 0.4))
	heart_rate_label = _create_hud_item(hbox, "HEART RATE", "82 BPM", Color(1.0, 0.60, 0.08))
	gait_label = _create_hud_item(hbox, "GAIT TELEMETRY", "LUNAR LOPE [Shift/C]", Color(0.0, 0.95, 1.0))
	gravity_label = _create_hud_item(hbox, "GRAVITY", "1.62 m/s² (0.166 g)", Color(0.4, 0.85, 1.0))
	compass_label = _create_hud_item(hbox, "HEADING", "045° NNE", Color(1.0, 0.60, 0.08))
	
	# Bottom bar: View mode & Mission Clock
	var bottom_hbox = HBoxContainer.new()
	bottom_hbox.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_hbox.offset_left = 36
	bottom_hbox.offset_right = -36
	bottom_hbox.offset_bottom = -16
	bottom_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bottom_hbox)
	
	view_mode_label = Label.new()
	view_mode_label.text = "VIEW: 3RD-PERSON MINION EVA [Mouse Wheel to Zoom]"
	view_mode_label.add_theme_color_override("font_color", Color(0.0, 0.95, 1.0, 0.85))
	view_mode_label.add_theme_font_size_override("font_size", 13)
	bottom_hbox.add_child(view_mode_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_hbox.add_child(spacer)
	
	mission_clock_label = Label.new()
	mission_clock_label.text = "EVA MET: 114:24:00"
	mission_clock_label.add_theme_color_override("font_color", Color(1.0, 0.60, 0.08, 0.85))
	mission_clock_label.add_theme_font_size_override("font_size", 13)
	bottom_hbox.add_child(mission_clock_label)

func _create_hud_item(parent: HBoxContainer, title: String, val: String, col: Color) -> Label:
	var vb = VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(vb)
	
	var t = Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 10)
	t.add_theme_color_override("font_color", Color(0.5, 0.75, 0.9, 0.75))
	vb.add_child(t)
	
	var v = Label.new()
	v.text = val
	v.add_theme_font_size_override("font_size", 13)
	v.add_theme_color_override("font_color", col)
	vb.add_child(v)
	return v

func _process(delta: float) -> void:
	_elapsed_sec += delta
	var hr = int(_elapsed_sec / 3600.0) + 114
	var mn = int(fmod(_elapsed_sec, 3600.0) / 60.0) + 24
	var sc = int(fmod(_elapsed_sec, 60.0))
	mission_clock_label.text = "EVA MET: %03d:%02d:%02d" % [hr, mn, sc]
	
	if not _player_ref:
		_find_player()
		return
	
	# Update gait mode
	var is_loping = false
	if "is_loping_mode" in _player_ref:
		is_loping = _player_ref.is_loping_mode
	gait_label.text = "LUNAR LOPE [Shift/C]" if is_loping else "SUIT WALK [Shift/C]"
	gait_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4) if is_loping else Color(0.0, 0.95, 1.0))
	
	# Update heart rate from exertion
	var exertion = 0.0
	if "exertion_level" in _player_ref:
		exertion = _player_ref.exertion_level
	var bpm = int(lerp(76.0, 138.0, exertion))
	heart_rate_label.text = "%d BPM" % bpm
	heart_rate_label.add_theme_color_override("font_color", Color(1.0, 0.60, 0.08) if bpm < 115 else Color(1.0, 0.35, 0.35))
	
	# Update heading and pitch
	if "camera_pivot" in _player_ref and _player_ref.camera_pivot:
		var yaw_deg = int(fmod(rad_to_deg(_player_ref.camera_pivot.rotation.y) + 360.0, 360.0))
		compass_label.text = "%03d°" % yaw_deg
	
	# Update gravity readout dynamically
	if "gravity" in _player_ref and gravity_label:
		var g_val = _player_ref.gravity
		var g_ratio = g_val / 9.80665
		gravity_label.text = "%.2f m/s² (%.3f g)" % [g_val, g_ratio]
