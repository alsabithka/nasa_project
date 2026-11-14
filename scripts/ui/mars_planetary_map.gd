extends CanvasLayer

# Echoes Beyond Earth - Mars Planetary Navigation & Holographic Globe System
# Features 3 zoom levels:
# 1. LOCAL TERRAIN VIEW: High-resolution local radar, elevation gradient, and immediate landmarks (<50 km)
# 2. REGIONAL SECTOR VIEW: Regional geological province (e.g. Isidis Basin, Tharsis, Valles Marineris)
# 3. GLOBAL PLANETARY GLOBE: Full 360° spherical interactive Mars map with real-time astronaut telemetry

enum MapZoomLevel { LOCAL, REGIONAL, GLOBAL }

var current_zoom: MapZoomLevel = MapZoomLevel.GLOBAL
var is_map_open: bool = false

var root_panel: PanelContainer
var header_title: Label
var coords_label: Label
var elevation_label: Label
var temp_label: Label
var distance_label: Label
var biome_label: Label
var landmark_list_container: VBoxContainer
var map_viewport_rect: ColorRect
var map_canvas: Control

var _player_ref: CharacterBody3D = null
var _planet_ref: Node3D = null
var _globe_rotation: float = 0.0

func _ready() -> void:
	layer = 12
	name = "MarsPlanetaryMap"
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_set_map_visible(false)
	call_deferred("_connect_references")

func _connect_references() -> void:
	_player_ref = get_tree().get_first_node_in_group("player") as CharacterBody3D
	_planet_ref = get_tree().get_first_node_in_group("spherical_planet") as Node3D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_M:
			toggle_map()
			get_viewport().set_input_as_handled()
		elif is_map_open:
			if event.physical_keycode == KEY_ESCAPE:
				_set_map_visible(false)
				get_viewport().set_input_as_handled()
			elif event.physical_keycode == KEY_1:
				set_zoom_level(MapZoomLevel.LOCAL)
			elif event.physical_keycode == KEY_2:
				set_zoom_level(MapZoomLevel.REGIONAL)
			elif event.physical_keycode == KEY_3:
				set_zoom_level(MapZoomLevel.GLOBAL)

func toggle_map() -> void:
	_set_map_visible(not is_map_open)

func _set_map_visible(vis: bool) -> void:
	is_map_open = vis
	visible = vis
	if root_panel:
		root_panel.visible = vis
	if vis:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		if _player_ref and not _player_ref.is_in_interaction():
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_zoom_level(lvl: MapZoomLevel) -> void:
	current_zoom = lvl
	if map_canvas:
		map_canvas.queue_redraw()

func _build_ui() -> void:
	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	root_panel = PanelContainer.new()
	root_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_panel.offset_left = 60
	root_panel.offset_right = -60
	root_panel.offset_top = 40
	root_panel.offset_bottom = -40
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.08, 0.12, 0.94)
	style.border_color = Color(0.85, 0.45, 0.22, 0.90) # Mars aerospace orange
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	root_panel.add_theme_stylebox_override("panel", style)
	root.add_child(root_panel)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 14)
	root_panel.add_child(main_vbox)

	# --- TOP BAR: TITLE & TELEMETRY ---
	var top_bar = HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 24)
	main_vbox.add_child(top_bar)

	header_title = Label.new()
	header_title.text = "MARS PLANETARY CARTOGRAPHIC NAVIGATION SYSTEM [M]"
	header_title.add_theme_font_size_override("font_size", 16)
	header_title.modulate = Color(1.0, 0.6, 0.3)
	top_bar.add_child(header_title)

	var top_spacer = Control.new()
	top_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(top_spacer)

	# View mode selector buttons
	var btn_local = Button.new()
	btn_local.text = "[1] LOCAL RADAR"
	btn_local.pressed.connect(func(): set_zoom_level(MapZoomLevel.LOCAL))
	top_bar.add_child(btn_local)

	var btn_reg = Button.new()
	btn_reg.text = "[2] REGIONAL SECTOR"
	btn_reg.pressed.connect(func(): set_zoom_level(MapZoomLevel.REGIONAL))
	top_bar.add_child(btn_reg)

	var btn_glob = Button.new()
	btn_glob.text = "[3] GLOBAL GLOBE"
	btn_glob.pressed.connect(func(): set_zoom_level(MapZoomLevel.GLOBAL))
	top_bar.add_child(btn_glob)

	var btn_close = Button.new()
	btn_close.text = "CLOSE [ESC]"
	btn_close.pressed.connect(func(): _set_map_visible(false))
	top_bar.add_child(btn_close)

	# --- TELEMETRY READOUTS ---
	var telem_panel = PanelContainer.new()
	var t_style = StyleBoxFlat.new()
	t_style.bg_color = Color(0.10, 0.13, 0.18, 0.85)
	t_style.set_corner_radius_all(4)
	telem_panel.add_theme_stylebox_override("panel", t_style)
	main_vbox.add_child(telem_panel)

	var telem_hbox = HBoxContainer.new()
	telem_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	telem_hbox.add_theme_constant_override("separation", 36)
	telem_panel.add_child(telem_hbox)

	coords_label = _create_telem_item(telem_hbox, "COORDINATES", "18.38°N, 077.58°E")
	elevation_label = _create_telem_item(telem_hbox, "DATUM ELEVATION", "-2.4 km")
	temp_label = _create_telem_item(telem_hbox, "SURFACE TEMP", "-63.5 °C")
	distance_label = _create_telem_item(telem_hbox, "DISTANCE TRAVELLED", "0.0 km")
	biome_label = _create_telem_item(telem_hbox, "GEOLOGICAL BIOME", "Lacustrine Delta Outcrop")

	# --- MIDDLE CONTENT: MAP CANVAS & LANDMARK SIDEBAR ---
	var content_hbox = HBoxContainer.new()
	content_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_hbox.add_theme_constant_override("separation", 16)
	main_vbox.add_child(content_hbox)

	# Map display canvas
	map_viewport_rect = ColorRect.new()
	map_viewport_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_viewport_rect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	map_viewport_rect.color = Color(0.04, 0.05, 0.08)
	content_hbox.add_child(map_viewport_rect)

	map_canvas = Control.new()
	map_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_canvas.draw.connect(_on_draw_map)
	map_viewport_rect.add_child(map_canvas)

	# Landmark list sidebar
	var side_panel = PanelContainer.new()
	side_panel.custom_minimum_size = Vector2(280, 0)
	var s_style = StyleBoxFlat.new()
	s_style.bg_color = Color(0.08, 0.10, 0.14, 0.80)
	s_style.set_corner_radius_all(4)
	side_panel.add_theme_stylebox_override("panel", s_style)
	content_hbox.add_child(side_panel)

	var side_vbox = VBoxContainer.new()
	side_vbox.add_theme_constant_override("separation", 8)
	side_panel.add_child(side_vbox)

	var side_title = Label.new()
	side_title.text = "MAJOR GEOGRAPHICAL SITES"
	side_title.add_theme_font_size_override("font_size", 12)
	side_title.modulate = Color(0.8, 0.85, 0.95)
	side_vbox.add_child(side_title)

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side_vbox.add_child(scroll)

	landmark_list_container = VBoxContainer.new()
	landmark_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	landmark_list_container.add_theme_constant_override("separation", 6)
	scroll.add_child(landmark_list_container)

	_populate_landmark_list()

func _create_telem_item(parent: HBoxContainer, title: String, default_val: String) -> Label:
	var vb = VBoxContainer.new()
	parent.add_child(vb)
	var t = Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 9)
	t.modulate = Color(0.55, 0.65, 0.75)
	vb.add_child(t)
	var v = Label.new()
	v.text = default_val
	v.add_theme_font_size_override("font_size", 12)
	v.modulate = Color(0.9, 0.95, 1.0)
	vb.add_child(v)
	return v

func _populate_landmark_list() -> void:
	if not _planet_ref and get_tree():
		_planet_ref = get_tree().get_first_node_in_group("spherical_planet") as Node3D
	
	var landmarks: Array = []
	if _planet_ref and "known_landmarks" in _planet_ref:
		landmarks = _planet_ref.known_landmarks
	
	for lm in landmarks:
		var btn = Button.new()
		btn.text = "%s\n(%04.1f°N, %05.1f°E) • %s" % [lm["name"], lm["lat"], lm["lon"], lm["type"]]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.add_theme_font_size_override("font_size", 10)
		btn.pressed.connect(func(): _on_landmark_selected(lm))
		landmark_list_container.add_child(btn)

func _on_landmark_selected(lm: Dictionary) -> void:
	if _planet_ref:
		print("[Navigation] Selected Landmark: ", lm["name"], " - ", lm["desc"])

func _process(delta: float) -> void:
	if not is_map_open:
		return

	_globe_rotation += delta * 0.15

	if not _player_ref:
		_player_ref = get_tree().get_first_node_in_group("player") as CharacterBody3D
	if not _planet_ref:
		_planet_ref = get_tree().get_first_node_in_group("spherical_planet") as Node3D

	if _player_ref and _planet_ref and _planet_ref.has_method("get_planetary_coords"):
		var p_data = _planet_ref.get_planetary_coords(_player_ref.global_position)
		var lat = p_data["lat"]
		var lon = p_data["lon"]
		var elev = p_data["elevation_km"]
		var temp = p_data["temp_c"]
		var biome = p_data["biome"]
		var dist_km = _player_ref.get_distance_travelled_km() if _player_ref.has_method("get_distance_travelled_km") else 0.0

		var lat_str = "%05.2f°%s" % [abs(lat), ("N" if lat >= 0 else "S")]
		var lon_str = "%06.2f°E" % lon
		coords_label.text = "%s, %s" % [lat_str, lon_str]
		elevation_label.text = "%+.2f km" % elev
		temp_label.text = "%.1f °C" % temp
		distance_label.text = "%.2f km" % dist_km
		biome_label.text = biome

	if map_canvas:
		map_canvas.queue_redraw()

func _on_draw_map() -> void:
	var size = map_canvas.size
	var center = size * 0.5

	match current_zoom:
		MapZoomLevel.LOCAL:
			_draw_local_radar(size, center)
		MapZoomLevel.REGIONAL:
			_draw_regional_map(size, center)
		MapZoomLevel.GLOBAL:
			_draw_global_globe(size, center)

# View 1: Local Tactical Radar (<50 km surroundings)
func _draw_local_radar(size: Vector2, center: Vector2) -> void:
	var r = minf(size.x, size.y) * 0.42
	# Radar rings
	for i in range(1, 5):
		var ring_r = r * (float(i) / 4.0)
		map_canvas.draw_arc(center, ring_r, 0, TAU, 48, Color(0.2, 0.4, 0.5, 0.4), 1.0)
		map_canvas.draw_string(ThemeDB.fallback_font, center + Vector2(6, -ring_r + 12), "%d km" % (i * 12), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.3, 0.7, 0.8, 0.6))

	# Crosshairs
	map_canvas.draw_line(center - Vector2(r, 0), center + Vector2(r, 0), Color(0.2, 0.4, 0.5, 0.3), 1.0)
	map_canvas.draw_line(center - Vector2(0, r), center + Vector2(0, r), Color(0.2, 0.4, 0.5, 0.3), 1.0)

	# Cardinal points
	map_canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-4, -r - 8), "N", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(0.9, 0.95, 1.0))
	map_canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-4, r + 18), "S", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(0.6, 0.7, 0.8))
	map_canvas.draw_string(ThemeDB.fallback_font, center + Vector2(r + 8, 4), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.6, 0.7, 0.8))
	map_canvas.draw_string(ThemeDB.fallback_font, center + Vector2(-r - 18, 4), "W", HORIZONTAL_ALIGNMENT_RIGHT, -1, 12, Color(0.6, 0.7, 0.8))

	# Astronaut position at center
	map_canvas.draw_circle(center, 5.0, Color(0.2, 0.9, 1.0))
	map_canvas.draw_arc(center, 9.0, 0, TAU, 24, Color(0.2, 0.9, 1.0, 0.6), 1.5)

# View 2: Regional Sector Map
func _draw_regional_map(size: Vector2, center: Vector2) -> void:
	var rect = Rect2(center - size * 0.42, size * 0.84)
	map_canvas.draw_rect(rect, Color(0.12, 0.08, 0.06), true)
	map_canvas.draw_rect(rect, Color(0.85, 0.45, 0.22, 0.8), false, 2.0)

	# Geographic grid lines
	for x_i in range(1, 5):
		var gx = rect.position.x + rect.size.x * (float(x_i) / 5.0)
		map_canvas.draw_line(Vector2(gx, rect.position.y), Vector2(gx, rect.end.y), Color(0.85, 0.45, 0.22, 0.2), 1.0)
	for y_i in range(1, 5):
		var gy = rect.position.y + rect.size.y * (float(y_i) / 5.0)
		map_canvas.draw_line(Vector2(rect.position.x, gy), Vector2(rect.end.x, gy), Color(0.85, 0.45, 0.22, 0.2), 1.0)

	map_canvas.draw_string(ThemeDB.fallback_font, rect.position + Vector2(12, 22), "SECTOR: JEZERO - ISIDIS BASIN (QUADRANT MC-13)", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.7, 0.3))

	# Player indicator
	var p_draw_pos = center + Vector2(-15, -20)
	map_canvas.draw_circle(p_draw_pos, 6.0, Color(0.2, 1.0, 0.4))
	map_canvas.draw_string(ThemeDB.fallback_font, p_draw_pos + Vector2(10, 4), "YOU ARE HERE", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.2, 1.0, 0.4))

# View 3: Full Spherical Global Globe
func _draw_global_globe(size: Vector2, center: Vector2) -> void:
	var r = minf(size.x, size.y) * 0.42
	# Mars globe disk
	map_canvas.draw_circle(center, r, Color(0.55, 0.24, 0.12)) # Rust red Martian disk
	# Atmospheric halo
	map_canvas.draw_arc(center, r + 2.0, 0, TAU, 64, Color(0.9, 0.55, 0.35, 0.6), 3.0)

	# Polar Ice Caps
	var north_pole_h = r * 0.18
	map_canvas.draw_circle(center - Vector2(0, r - north_pole_h * 0.5), north_pole_h, Color(0.95, 0.96, 0.98, 0.95))
	var south_pole_h = r * 0.15
	map_canvas.draw_circle(center + Vector2(0, r - south_pole_h * 0.5), south_pole_h, Color(0.92, 0.94, 0.96, 0.90))

	# Latitude parallels
	for lat_i in [-60, -30, 0, 30, 60]:
		var y_off = -sin(deg_to_rad(lat_i)) * r
		var half_w = sqrt(maxf(0.0, r * r - y_off * y_off))
		map_canvas.draw_line(center + Vector2(-half_w, y_off), center + Vector2(half_w, y_off), Color(0.7, 0.35, 0.2, 0.35), 1.0)

	# Longitude meridians (ellipses)
	for lon_i in [0, 45, 90, 135]:
		var phase = deg_to_rad(lon_i) + _globe_rotation
		var x_r = abs(cos(phase)) * r
		if x_r > 5.0:
			map_canvas.draw_arc(center, x_r, -PI * 0.5, PI * 0.5, 32, Color(0.7, 0.35, 0.2, 0.25), 1.0)
			map_canvas.draw_arc(center, x_r, PI * 0.5, PI * 1.5, 32, Color(0.7, 0.35, 0.2, 0.25), 1.0)

	# Draw major landmark positions projected on the rotating globe
	var landmarks: Array = []
	if _planet_ref and "known_landmarks" in _planet_ref:
		landmarks = _planet_ref.known_landmarks

	for lm in landmarks:
		var lat_rad = deg_to_rad(lm["lat"])
		var lon_rad = deg_to_rad(lm["lon"]) + _globe_rotation
		var x = cos(lat_rad) * sin(lon_rad)
		var z = cos(lat_rad) * cos(lon_rad)
		var y = sin(lat_rad)

		# If on facing hemisphere (z > 0)
		if z > -0.1:
			var pt = center + Vector2(x * r, -y * r)
			var alpha = clampf(z + 0.2, 0.2, 1.0)
			map_canvas.draw_circle(pt, 4.0, Color(1.0, 0.8, 0.2, alpha))
			map_canvas.draw_string(ThemeDB.fallback_font, pt + Vector2(6, 4), lm["name"].split(" ")[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1.0, 0.9, 0.6, alpha))

	# Player position on globe
	if _player_ref and _planet_ref and _planet_ref.has_method("get_planetary_coords"):
		var p_data = _planet_ref.get_planetary_coords(_player_ref.global_position)
		var p_lat_rad = deg_to_rad(p_data["lat"])
		var p_lon_rad = deg_to_rad(p_data["lon"]) + _globe_rotation
		var px = cos(p_lat_rad) * sin(p_lon_rad)
		var pz = cos(p_lat_rad) * cos(p_lon_rad)
		var py = sin(p_lat_rad)

		if pz > -0.15:
			var player_pt = center + Vector2(px * r, -py * r)
			map_canvas.draw_circle(player_pt, 6.0, Color(0.2, 1.0, 0.4))
			map_canvas.draw_arc(player_pt, 10.0, 0, TAU, 24, Color(0.2, 1.0, 0.4, 0.8), 2.0)
			map_canvas.draw_string(ThemeDB.fallback_font, player_pt + Vector2(12, 4), "ASTRONAUT EVA", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.2, 1.0, 0.4))
