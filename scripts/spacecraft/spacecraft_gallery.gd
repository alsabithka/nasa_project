extends Node3D

# Echoes Beyond Earth - Solar System Historical Spacecraft Exhibition & Gallery
# Showcases deep-space and planetary spacecraft outside Mars surface:
# 1. Dawn Spacecraft (Ceres Orbit)
# 2. NEAR Shoemaker (Asteroid 433 Eros)
# 3. Pioneer 10 (Interstellar Space)
# 4. Pioneer 11 (Interstellar Space)
# 5. Kepler Space Telescope (Earth-trailing Heliocentric Orbit)

const HistoricalSpacecraftModels = preload("res://scripts/spacecraft/historical_spacecraft_models.gd")
const SpacecraftInspectorHUD = preload("res://scripts/ui/spacecraft_inspector_hud.gd")

const UITokens = preload("res://scripts/ui/ui_tokens.gd")

var current_craft_index: int = 0

var spacecraft_list: Array[Dictionary] = [
	{
		"id": "dawn",
		"name": "Dawn Spacecraft",
		"target": "Dwarf Planet Ceres & Vesta",
		"launch": "September 27, 2007",
		"status": "Inactive (Stable Uncontrolled Ceres Orbit)",
		"dist_au": "2.8 AU from Sun",
		"notes": "First spacecraft to orbit two extraterrestrial bodies. Powered by 3 NSTAR Xenon ion thrusters with 19.7m solar wings."
	},
	{
		"id": "near_shoemaker",
		"name": "NEAR Shoemaker",
		"target": "Asteroid 433 Eros",
		"launch": "February 17, 1996",
		"status": "Inactive (Resting on Eros Surface)",
		"dist_au": "1.46 AU from Sun",
		"notes": "First spacecraft to orbit and softly land on an asteroid. Resting permanently on its 4 solar array tips."
	},
	{
		"id": "pioneer_10",
		"name": "Pioneer 10",
		"target": "Jupiter Flyby & Interstellar Space",
		"launch": "March 2, 1972",
		"status": "Inactive (Interstellar Trajectory towards Aldebaran)",
		"dist_au": "~136 AU from Earth",
		"notes": "First probe to traverse Asteroid Belt and fly by Jupiter. Carries the gold-anodized Pioneer Plaque."
	},
	{
		"id": "pioneer_11",
		"name": "Pioneer 11",
		"target": "Jupiter & Saturn Flyby",
		"launch": "April 5, 1973",
		"status": "Inactive (Interstellar Trajectory towards Aquila)",
		"dist_au": "~114 AU from Earth",
		"notes": "First probe to encounter Saturn and its rings. Sister craft to Pioneer 10 carrying the engraved plaque."
	},
	{
		"id": "kepler",
		"name": "Kepler Space Telescope",
		"target": "Earth-Trailing Heliocentric Orbit",
		"launch": "March 7, 2009",
		"status": "Retired (Earth-Trailing Heliocentric Orbit)",
		"dist_au": "1.02 AU from Sun",
		"notes": "Discovered over 2,600 exoplanets using a 0.95m Schmidt photometer and curved solar array sunshade."
	}
]

# Scene references
@onready var mount_point: Node3D = $MountPoint
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera_pitch: Node3D = $CameraPivot/CameraPitch
@onready var camera: Camera3D = $CameraPivot/CameraPitch/Camera3D
@onready var sun_light: DirectionalLight3D = $SunLight

# UI Nodes
var ui_layer: CanvasLayer
var title_label: Label
var subtitle_label: Label
var stats_label: Label
var inspector_hud: CanvasLayer = null

# Orbit Camera State
var yaw: float = 0.0
var pitch: float = 0.25
var cam_distance: float = 12.0
var target_cam_distance: float = 12.0
var is_dragging: bool = false
var auto_rotate: bool = true
var _last_mouse_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	_setup_environment()
	_setup_ui()
	_load_spacecraft(current_craft_index)

func _setup_environment() -> void:
	# Add backdrop stars and celestial bodies
	var env_node = get_node_or_null("WorldEnvironment")
	if not env_node:
		env_node = WorldEnvironment.new()
		var env = Environment.new()
		env.background_mode = Environment.BG_COLOR
		env.background_color = Color(0.01, 0.01, 0.02)
		env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.ambient_light_color = Color(0.08, 0.09, 0.12)
		env.ambient_light_energy = 0.65
		env.tonemap_mode = Environment.TONE_MAPPER_ACES
		env_node.environment = env
		add_child(env_node)

	if not sun_light:
		sun_light = DirectionalLight3D.new()
		sun_light.name = "SunLight"
		sun_light.light_color = Color(1.0, 0.98, 0.94)
		sun_light.light_energy = 1.85
		sun_light.shadow_enabled = true
		sun_light.rotation_degrees = Vector3(-35, 45, 0)
		add_child(sun_light)

	# Faint starry dust field
	var stars = MeshInstance3D.new()
	stars.name = "StarField"
	var sphere = SphereMesh.new()
	sphere.radius = 180.0
	sphere.height = 360.0
	sphere.radial_segments = 32
	sphere.rings = 16
	var s_mat = StandardMaterial3D.new()
	s_mat.cull_mode = BaseMaterial3D.CULL_FRONT
	s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	s_mat.albedo_color = Color(0.02, 0.02, 0.04)
	sphere.material = s_mat
	stars.mesh = sphere
	add_child(stars)

func _setup_ui() -> void:
	ui_layer = CanvasLayer.new()
	ui_layer.layer = UITokens.LAYER_OVERLAYS  # 10
	add_child(ui_layer)

	var root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(root)

	# Phase 6: shared ArchiveCard style (INK_800, 0px radius, PAPER_500 border)
	var style = StyleBoxFlat.new()
	style.bg_color = UITokens.INK_800
	style.border_color = UITokens.PAPER_500
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12

	# Top Header Panel
	var top_panel = PanelContainer.new()
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 32
	top_panel.offset_right = -32
	top_panel.offset_top = 20
	top_panel.offset_bottom = 120
	root.add_child(top_panel)
	top_panel.add_theme_stylebox_override("panel", style)

	var top_vbox = VBoxContainer.new()
	top_panel.add_child(top_vbox)

	var h_top = HBoxContainer.new()
	top_vbox.add_child(h_top)

	var title_vbox = VBoxContainer.new()
	title_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_top.add_child(title_vbox)

	title_label = Label.new()
	title_label.text = "NASA HISTORICAL HARDWARE EXHIBITION"
	title_label.add_theme_font_size_override("font_size", UITokens.TEXT_TITLE)
	title_label.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD)
	title_vbox.add_child(title_label)

	subtitle_label = Label.new()
	subtitle_label.text = "Solar System Collection - Deep Space & Planetary Missions"
	subtitle_label.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
	subtitle_label.add_theme_color_override("font_color", UITokens.PAPER_300)
	title_vbox.add_child(subtitle_label)

	var exit_btn = Button.new()
	exit_btn.text = "Return to Menu [ESC]"
	exit_btn.pressed.connect(_on_exit_pressed)
	h_top.add_child(exit_btn)

	stats_label = Label.new()
	stats_label.text = "Launch: 2007 | Status: Inactive"
	stats_label.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
	stats_label.add_theme_color_override("font_color", UITokens.PAPER_500)
	top_vbox.add_child(stats_label)

	# Bottom Spacecraft Selection Bar
	# B4 FIX: increased height and wrapped in ScrollContainer to prevent overflow at 1280px
	var bot_panel = PanelContainer.new()
	bot_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot_panel.offset_left = 32
	bot_panel.offset_right = -32
	bot_panel.offset_bottom = -20
	bot_panel.offset_top = -88
	root.add_child(bot_panel)
	# Reuse same ArchiveCard style
	bot_panel.add_theme_stylebox_override("panel", style)

	var bot_scroll = ScrollContainer.new()
	bot_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	bot_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bot_panel.add_child(bot_scroll)

	var bot_hbox = HBoxContainer.new()
	bot_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	bot_hbox.add_theme_constant_override("separation", 12)
	bot_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot_scroll.add_child(bot_hbox)

	var prev_btn = Button.new()
	prev_btn.text = "< Prev Craft [Q]"
	prev_btn.pressed.connect(select_prev_spacecraft)
	bot_hbox.add_child(prev_btn)

	for i in range(spacecraft_list.size()):
		var btn = Button.new()
		var sc = spacecraft_list[i]
		btn.text = "[%d] %s" % [i + 1, sc["name"]]
		var idx = i
		btn.pressed.connect(func(): _load_spacecraft(idx))
		bot_hbox.add_child(btn)

	var next_btn = Button.new()
	next_btn.text = "Next Craft [E] >"
	next_btn.pressed.connect(select_next_spacecraft)
	bot_hbox.add_child(next_btn)

	var inspect_btn = Button.new()
	inspect_btn.text = "Inspect Components [I / Space]"
	inspect_btn.pressed.connect(toggle_component_inspector)
	bot_hbox.add_child(inspect_btn)

func _load_spacecraft(idx: int) -> void:
	current_craft_index = clampi(idx, 0, spacecraft_list.size() - 1)
	var sc = spacecraft_list[current_craft_index]

	# Clear previous model
	for c in mount_point.get_children():
		c.queue_free()

	# Build procedural 3D model
	var model: Node3D = null
	match sc["id"]:
		"dawn":
			model = HistoricalSpacecraftModels.build_dawn_spacecraft()
			target_cam_distance = 18.0
		"near_shoemaker":
			model = HistoricalSpacecraftModels.build_near_shoemaker()
			_add_eros_surface_context()
			target_cam_distance = 8.0
		"pioneer_10":
			model = HistoricalSpacecraftModels.build_pioneer_probe(10)
			target_cam_distance = 9.0
		"pioneer_11":
			model = HistoricalSpacecraftModels.build_pioneer_probe(11)
			target_cam_distance = 9.0
		"kepler":
			model = HistoricalSpacecraftModels.build_kepler_telescope()
			target_cam_distance = 10.0

	if model:
		mount_point.add_child(model)

	# Update UI text
	if title_label:
		title_label.text = sc["name"].to_upper()
	if subtitle_label:
		subtitle_label.text = "Destination: %s | %s" % [sc["target"], sc["status"]]
	if stats_label:
		stats_label.text = "Launch Date: %s | Distance: %s\n%s" % [sc["launch"], sc["dist_au"], sc["notes"]]

	# Reset inspector if currently open
	if inspector_hud:
		inspector_hud.open_inspector(mount_point, sc["id"])

func _add_eros_surface_context() -> void:
	# Add dusty irregular boulder terrain under NEAR Shoemaker
	var ground = MeshInstance3D.new()
	var g_box = BoxMesh.new()
	g_box.size = Vector3(10.0, 0.4, 10.0)
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.35, 0.32, 0.30)
	g_mat.roughness = 0.95
	g_box.material = g_mat
	ground.mesh = g_box
	ground.position = Vector3(0, -0.2, 0)
	mount_point.add_child(ground)

	# Scattered asteroid boulders
	for i in range(8):
		var b = MeshInstance3D.new()
		var b_mesh = BoxMesh.new()
		var s = 0.3 + float(i % 3) * 0.25
		b_mesh.size = Vector3(s, s * 0.8, s * 1.1)
		var b_mat = StandardMaterial3D.new()
		b_mat.albedo_color = Color(0.28, 0.26, 0.25)
		b_mat.roughness = 0.9
		b_mesh.material = b_mat
		b.mesh = b_mesh
		var a = float(i) * 0.8
		b.position = Vector3(cos(a) * 3.2, 0.15, sin(a) * 3.2)
		b.rotation_degrees = Vector3(15 * i, 30 * i, 10)
		mount_point.add_child(b)

func select_next_spacecraft() -> void:
	var next_idx = (current_craft_index + 1) % spacecraft_list.size()
	_load_spacecraft(next_idx)

func select_prev_spacecraft() -> void:
	var prev_idx = (current_craft_index - 1 + spacecraft_list.size()) % spacecraft_list.size()
	_load_spacecraft(prev_idx)

func toggle_component_inspector() -> void:
	if inspector_hud:
		inspector_hud.queue_free()
		inspector_hud = null
		return

	inspector_hud = SpacecraftInspectorHUD.new()
	inspector_hud.inspection_closed.connect(_on_inspector_closed)
	add_child(inspector_hud)
	var sc = spacecraft_list[current_craft_index]
	inspector_hud.open_inspector(mount_point, sc["id"])

func _on_inspector_closed() -> void:
	inspector_hud = null

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _process(delta: float) -> void:
	# Smooth camera zoom lerp
	cam_distance = lerp(cam_distance, target_cam_distance, delta * 6.0)
	if camera:
		camera.position.z = cam_distance

	# Auto turntable rotation when not dragging
	if auto_rotate and not is_dragging:
		yaw += delta * 0.2

	if camera_pivot:
		camera_pivot.rotation.y = yaw
	if camera_pitch:
		camera_pitch.rotation.x = pitch

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			is_dragging = event.pressed
			_last_mouse_pos = event.position
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_cam_distance = clampf(target_cam_distance - 1.2, 3.0, 35.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_cam_distance = clampf(target_cam_distance + 1.2, 3.0, 35.0)

	elif event is InputEventMouseMotion and is_dragging:
		var delta_pos = event.position - _last_mouse_pos
		_last_mouse_pos = event.position
		yaw -= delta_pos.x * 0.006
		pitch = clampf(pitch - delta_pos.y * 0.006, -1.2, 1.2)

	elif event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				if inspector_hud:
					toggle_component_inspector()
				else:
					_on_exit_pressed()
			KEY_1:
				_load_spacecraft(0)
			KEY_2:
				_load_spacecraft(1)
			KEY_3:
				_load_spacecraft(2)
			KEY_4:
				_load_spacecraft(3)
			KEY_5:
				_load_spacecraft(4)
			KEY_Q:
				select_prev_spacecraft()
			KEY_E:
				select_next_spacecraft()
			KEY_I:
				toggle_component_inspector()
			KEY_SPACE:
				auto_rotate = not auto_rotate
