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
const InputSetup = preload("res://scripts/input/input_setup.gd")

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

# UI Nodes (Phase 6: header + info panel + selector rail built from shared components)
var ui_layer: CanvasLayer
var title_label: Label        # craft name (header)
var subtitle_label: Label     # destination (header caption)
var stats_label: Label        # historical notes (info panel)
var inspector_hud: CanvasLayer = null
var position_label: Label     # "02 / 05"
var rail_panel: Control       # selector rail + actions (hidden while the inspector is open)
var info_panel: Control       # data rows + notes (hidden while the inspector is open)
var _fields: Dictionary = {}   # launch / distance / status value labels
var _rotate_button: Button

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
	# Keyboard / gamepad users start on the current craft in the rail.
	if not _craft_buttons.is_empty():
		_craft_buttons[current_craft_index].grab_focus.call_deferred()

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

var _craft_buttons: Array[Button] = []

func _setup_ui() -> void:
	InputSetup.ensure()
	ui_layer = CanvasLayer.new()
	ui_layer.layer = UITokens.LAYER_OVERLAYS  # 10
	add_child(ui_layer)

	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE    # the 3D view stays draggable behind the UI
	root.theme = UITokens.theme()
	ui_layer.add_child(root)

	# Three zones in one margin box: header (top) / info (right, middle) / rail (bottom).
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, UITokens.SP_6)
	root.add_child(margin)
	var zones := VBoxContainer.new()
	zones.mouse_filter = Control.MOUSE_FILTER_IGNORE
	zones.add_theme_constant_override("separation", UITokens.SP_3)
	margin.add_child(zones)

	# ── Header ──────────────────────────────────────────────────────────────────────────
	var header := ArchiveCard.new()
	zones.add_child(header)
	var h_row := HBoxContainer.new()
	h_row.add_theme_constant_override("separation", UITokens.SP_4)
	header.add_child(h_row)
	var h_col := VBoxContainer.new()
	h_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_col.add_theme_constant_override("separation", 0)
	h_row.add_child(h_col)
	subtitle_label = Label.new()
	subtitle_label.theme_type_variation = &"CaptionLabel"
	subtitle_label.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD)
	h_col.add_child(subtitle_label)
	title_label = Label.new()
	title_label.theme_type_variation = &"DisplayLabel"
	h_col.add_child(title_label)
	position_label = Label.new()
	position_label.theme_type_variation = &"StatLabel"
	position_label.add_theme_color_override("font_color", UITokens.PAPER_300)
	position_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h_row.add_child(position_label)
	var exit_btn := Button.new()
	exit_btn.text = "Return to menu"
	exit_btn.icon = UITokens.icon("close")
	exit_btn.theme_type_variation = &"GhostButton"
	exit_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	exit_btn.pressed.connect(_on_exit_pressed)
	h_row.add_child(exit_btn)
	var esc_cap := KeyCap.new()
	esc_cap.label_override = "Esc"
	esc_cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h_row.add_child(esc_cap)

	# ── Middle: spacer (3D view) + info panel on the right ──────────────────────────────
	var middle := HBoxContainer.new()
	middle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	middle.size_flags_vertical = Control.SIZE_EXPAND_FILL
	zones.add_child(middle)
	var spacer := Control.new()
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	middle.add_child(spacer)

	var info := ArchiveCard.new()
	info.show_offset_shadow = true
	info.custom_minimum_size = Vector2(360, 0)
	info.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	middle.add_child(info)
	info_panel = info
	var i_col := VBoxContainer.new()
	i_col.add_theme_constant_override("separation", UITokens.SP_3)
	info.add_child(i_col)
	var badges := HBoxContainer.new()
	badges.add_theme_constant_override("separation", UITokens.SP_2)
	badges.add_child(Badge.make(Badge.Kind.ARCHIVE))
	i_col.add_child(badges)
	var data := GridContainer.new()
	data.columns = 2
	data.add_theme_constant_override("h_separation", UITokens.SP_6)
	data.add_theme_constant_override("v_separation", UITokens.SP_3)
	i_col.add_child(data)
	_add_field(data, "launch", "LAUNCH")
	_add_field(data, "distance", "DISTANCE")
	var status_col := VBoxContainer.new()
	status_col.add_theme_constant_override("separation", 2)
	status_col.add_child(_gallery_caption("STATUS"))
	_fields["status"] = _gallery_body()
	status_col.add_child(_fields["status"])
	i_col.add_child(status_col)
	var rule := ColorRect.new()
	rule.color = UITokens.INK_600
	rule.custom_minimum_size = Vector2(0, 1)
	i_col.add_child(rule)
	var notes_col := VBoxContainer.new()
	notes_col.add_theme_constant_override("separation", 2)
	notes_col.add_child(_gallery_caption("WHY IT MATTERS"))
	stats_label = _gallery_body()
	notes_col.add_child(stats_label)
	i_col.add_child(notes_col)

	# ── Rail: one toggle per craft (wraps, never off-screen) + actions ──────────────────
	var rail := ArchiveCard.new()
	zones.add_child(rail)
	rail_panel = rail
	var r_col := VBoxContainer.new()
	r_col.add_theme_constant_override("separation", UITokens.SP_2)
	rail.add_child(r_col)

	var craft_flow := HFlowContainer.new()
	craft_flow.add_theme_constant_override("h_separation", UITokens.SP_1)
	craft_flow.add_theme_constant_override("v_separation", UITokens.SP_1)
	r_col.add_child(craft_flow)
	_craft_buttons.clear()
	for i in range(spacecraft_list.size()):
		var btn := Button.new()
		btn.text = "%02d  %s" % [i + 1, spacecraft_list[i]["name"]]
		btn.theme_type_variation = &"TabButton"
		btn.toggle_mode = true
		btn.focus_mode = Control.FOCUS_ALL
		var idx := i
		btn.pressed.connect(func() -> void: _load_spacecraft(idx))
		# Selection follows focus: arrow keys / D-pad browse the collection.
		btn.focus_entered.connect(func() -> void:
			if idx != current_craft_index:
				_load_spacecraft(idx))
		craft_flow.add_child(btn)
		_craft_buttons.append(btn)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", UITokens.SP_3)
	r_col.add_child(actions)
	actions.add_child(_action_button("Previous", "chevron_left", "gallery_prev", select_prev_spacecraft, &"GhostButton"))
	actions.add_child(_action_button("Next", "chevron_right", "gallery_next", select_next_spacecraft, &"GhostButton"))
	var grow := Control.new()
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	actions.add_child(grow)
	var rot := _action_button("Auto-rotate: On", "", "gallery_rotate", toggle_auto_rotate, &"GhostButton")
	_rotate_button = rot.get_child(1) as Button
	actions.add_child(rot)
	actions.add_child(_action_button("Inspect components", "scan", "gallery_inspect", toggle_component_inspector, &"PrimaryButton"))
	_sync_craft_buttons()


## [KeyCap] [Button] pair; the cap reads the InputMap so rebinding shows up automatically.
func _action_button(text: String, icon_name: String, action: String, cb: Callable, variation: StringName) -> HBoxContainer:
	var holder := HBoxContainer.new()
	holder.add_theme_constant_override("separation", UITokens.SP_2)
	var cap := KeyCap.new()
	cap.action_name = action
	cap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	holder.add_child(cap)
	var b := Button.new()
	b.text = text
	if icon_name != "":
		b.icon = UITokens.icon(icon_name)
	b.theme_type_variation = variation
	b.pressed.connect(cb)
	holder.add_child(b)
	return holder


func _add_field(grid: GridContainer, key: String, caption: String) -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.add_child(_gallery_caption(caption))
	var l := Label.new()
	l.theme_type_variation = &"StatLabel"
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(l)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_child(v)
	_fields[key] = l


func _gallery_caption(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.theme_type_variation = &"CaptionLabel"
	l.add_theme_color_override("font_color", UITokens.PAPER_300)
	return l


func _gallery_body() -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_color_override("font_color", UITokens.PAPER_100)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _sync_craft_buttons() -> void:
	for i in range(_craft_buttons.size()):
		_craft_buttons[i].set_pressed_no_signal(i == current_craft_index)

func toggle_auto_rotate() -> void:
	auto_rotate = not auto_rotate
	if _rotate_button != null:
		_rotate_button.text = "Auto-rotate: On" if auto_rotate else "Auto-rotate: Off"

func _load_spacecraft(idx: int) -> void:
	current_craft_index = clampi(idx, 0, spacecraft_list.size() - 1)
	_sync_craft_buttons()
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

	# Update UI text (all values come from spacecraft_list; nothing is invented here)
	if title_label:
		title_label.text = sc["name"]
	if subtitle_label:
		subtitle_label.text = ("DESTINATION · %s" % sc["target"]).to_upper()
	if position_label:
		position_label.text = "%02d / %02d" % [current_craft_index + 1, spacecraft_list.size()]
	if _fields.has("launch"):
		_fields["launch"].text = sc["launch"]
		_fields["distance"].text = sc["dist_au"]
		_fields["status"].text = sc["status"]
	if stats_label:
		stats_label.text = sc["notes"]

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
		_set_inspecting(false)
		return

	inspector_hud = SpacecraftInspectorHUD.new()
	inspector_hud.inspection_closed.connect(_on_inspector_closed)
	add_child(inspector_hud)
	var sc = spacecraft_list[current_craft_index]
	inspector_hud.open_inspector(mount_point, sc["id"])
	_set_inspecting(true)

## The inspector occupies the bottom of the screen: the rail and info panel step aside.
func _set_inspecting(on: bool) -> void:
	if rail_panel:
		rail_panel.visible = not on
	if info_panel:
		info_panel.visible = not on
	if not on and current_craft_index < _craft_buttons.size():
		_craft_buttons[current_craft_index].grab_focus.call_deferred()

func _on_inspector_closed() -> void:
	inspector_hud = null
	_set_inspecting(false)

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

	# Phase 6: actions only (no raw KEY_ literals). Q/E/Left/Right cycle, I inspects, Space rotates.
	elif event.is_action_pressed("ui_cancel"):
		if inspector_hud:
			toggle_component_inspector()
		else:
			_on_exit_pressed()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("gallery_prev"):
		select_prev_spacecraft()
	elif event.is_action_pressed("gallery_next"):
		select_next_spacecraft()
	elif event.is_action_pressed("gallery_inspect"):
		toggle_component_inspector()
	elif event.is_action_pressed("gallery_rotate"):
		toggle_auto_rotate()
