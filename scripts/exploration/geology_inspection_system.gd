extends Node3D

# Echoes Beyond Earth - Real Scientific Geological Inspection System
# Recreates astronaut fieldwork and lunar sample curation using authentic NASA Lunar Sample Compendium data:
# 1. Sample 70017 - Camelot Crater Subfloor High-Ti Basalt
# 2. Sample 74220 - Shorty Crater Orange Pyroclastic Volcanic Glass
# 3. Sample 76015 - Station 6 North Massif Impact Melt Breccia
# 4. Sample 70181 - Taurus-Littrow Drive Tube Stratified Regolith

signal inspection_started(sample_data: Dictionary)
signal inspection_ended()

var active_sample: Dictionary = {}
var is_inspecting: bool = false
var _inspection_ui: CanvasLayer = null

# Verified NASA Apollo 17 Geological Catalog
var geological_samples: Dictionary = {
	"sample_70017": {
		"id": "Apollo Sample 70017",
		"name": "Coarse-Grained High-Ti Basalt",
		"station": "Station 1 - Camelot Crater Rim",
		"location": Vector3(19.5, 0.0, 13.5),
		"age": "3.75 ± 0.05 Billion Years",
		"petrology": "Sub-floor Ilmenite Basalt (Mare Basalt)",
		"minerals": "45% Clinopyroxene, 30% Plagioclase (An88), 18% Ilmenite (FeTiO3), 7% Olivine",
		"summary": "Excavated from deep sub-floor bedrock by the Camelot impact. High titanium content gives dark color to Taurus-Littrow mare.",
		"color": Color(0.24, 0.25, 0.28),
		"roughness": 0.88,
		"metallic": 0.15
	},
	"sample_74220": {
		"id": "Apollo Sample 74220",
		"name": "Orange Pyroclastic Volcanic Glass Beads",
		"station": "Station 4 - Shorty Crater Rim",
		"location": Vector3(-35.0, 0.0, 8.0),
		"age": "3.63 ± 0.04 Billion Years",
		"petrology": "Ultramafic Volcanic Pyroclastic Deposit",
		"minerals": "Amorphous Orange Glass Spherules (SiO2 40%, FeO 22%, TiO2 8.8%, Zn, S, Pb coatings)",
		"summary": "Discovered by geologist Harrison Schmitt. Pristine pyroclastic ash erupted from lunar mantle depths exceeding 400 km.",
		"color": Color(0.68, 0.42, 0.18),
		"roughness": 0.45,
		"metallic": 0.05
	},
	"sample_76015": {
		"id": "Apollo Sample 76015",
		"name": "North Massif Impact Melt Breccia",
		"station": "Station 6 - Base of North Massif (Tracy's Rock)",
		"location": Vector3(10.0, 0.0, 32.0),
		"age": "3.93 ± 0.03 Billion Years (Serenitatis Impact)",
		"petrology": "Poikilitic Microporphyritic Norite Breccia",
		"minerals": "60% Anorthositic Plagioclase, 32% Low-Ca Pyroxene (Enstatite), 8% Olivine & Ilmenite",
		"summary": "Sampled from giant fractured 5-meter boulder rolled down the North Massif slope. Documents ancient lunar cataclysm bombardment.",
		"color": Color(0.52, 0.54, 0.56),
		"roughness": 0.94,
		"metallic": 0.02
	},
	"sample_70181": {
		"id": "Apollo Sample 70181",
		"name": "Taurus-Littrow Subsurface Regolith Core",
		"station": "ALSEP / Central Valley Station",
		"location": Vector3(-18.5, 0.0, 14.5),
		"age": "Recent Regolith (4.0 Gy Bedrock Origin)",
		"petrology": "Cohesive Mature Lunar Soil Stratigraphy",
		"minerals": "Agglutinates (glass-bonded regolith), Pyroxene, Plagioclase, Nanophase Metallic Iron (Fe0)",
		"summary": "Drive tube core sample preserving solar wind implanted helium-3, micrometeorite impact glass, and abrasive silicate shards.",
		"color": Color(0.34, 0.36, 0.38),
		"roughness": 0.98,
		"metallic": 0.01
	}
}

func _ready() -> void:
	name = "GeologyInspectionSystem"
	add_to_group("geology_system")
	call_deferred("_spawn_sample_markers")

# Spawns scientific survey flags and rock specimens at the real coordinates
func _spawn_sample_markers() -> void:
	var terrain = get_tree().get_first_node_in_group("terrain")
	if not terrain and get_parent():
		terrain = get_parent().get_node_or_null("Terrain")
	
	for s_key in geological_samples.keys():
		var data = geological_samples[s_key]
		var pos: Vector3 = data["location"]
		
		if terrain and terrain.has_method("get_terrain_height"):
			pos.y = terrain.get_terrain_height(pos.x, pos.z)
			data["location"] = pos
		
		# Root node for interactive specimen
		var sample_root = Area3D.new()
		sample_root.name = "Sample_" + s_key
		sample_root.collision_layer = 8
		sample_root.collision_mask = 2
		sample_root.position = pos
		sample_root.set_meta("sample_key", s_key)
		add_child(sample_root)
		
		# Collision shape
		var col = CollisionShape3D.new()
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = 2.4
		col.shape = sphere_shape
		sample_root.add_child(col)
		
		# Rock visual mesh
		var rock_mesh = MeshInstance3D.new()
		var mesh = SphereMesh.new()
		mesh.radius = 0.35
		mesh.height = 0.55
		mesh.radial_segments = 7
		mesh.rings = 4
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = data["color"]
		mat.roughness = data["roughness"]
		mat.metallic = data["metallic"]
		mesh.material = mat
		
		rock_mesh.mesh = mesh
		rock_mesh.position = Vector3(0, 0.25, 0)
		rock_mesh.rotation_degrees = Vector3(15, 30, -10)
		sample_root.add_child(rock_mesh)
		
		# Scientific Survey Gnomon / Flag marker (Apollo sun-compass gnomon for photometric scale)
		var gnomon = MeshInstance3D.new()
		var cyl = CylinderMesh.new()
		cyl.top_radius = 0.015
		cyl.bottom_radius = 0.015
		cyl.height = 0.65
		var g_mat = StandardMaterial3D.new()
		g_mat.albedo_color = Color(0.9, 0.75, 0.1) # Photometric scale rod
		cyl.material = g_mat
		gnomon.mesh = cyl
		gnomon.position = Vector3(0.4, 0.32, 0)
		sample_root.add_child(gnomon)
		
		# In-world prompt label
		var label = Label3D.new()
		label.text = "[F] Examine " + data["id"]
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(0, 0.95, 0)
		label.modulate = Color(0.3, 0.9, 1.0)
		label.font_size = 28
		label.outline_size = 8
		label.visible = false
		label.name = "PromptLabel"
		sample_root.add_child(label)
		
		sample_root.body_entered.connect(func(body):
			if body.is_in_group("player"):
				label.visible = true
		)
		sample_root.body_exited.connect(func(body):
			if body.is_in_group("player"):
				label.visible = false
		)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inspect_geology") or (event is InputEventKey and event.pressed and event.physical_keycode == KEY_F):
		if is_inspecting:
			close_inspection()
		else:
			_try_inspect_nearby_sample()
	elif event.is_action_pressed("ui_cancel") and is_inspecting:
		close_inspection()
		get_viewport().set_input_as_handled()  # Esc policy: the top modal consumes it

func _try_inspect_nearby_sample() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	var closest_key = ""
	var closest_dist = 3.2
	
	for s_key in geological_samples.keys():
		var data = geological_samples[s_key]
		var dist = player.global_position.distance_to(data["location"])
		if dist < closest_dist:
			closest_dist = dist
			closest_key = s_key
	
	if closest_key != "":
		start_inspection(closest_key)

func start_inspection(sample_key: String) -> void:
	if not geological_samples.has(sample_key):
		return
	
	active_sample = geological_samples[sample_key]
	is_inspecting = true
	inspection_started.emit(active_sample)
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("begin_interaction"):
		var anchor = active_sample["location"] + Vector3(0, 0, 1.2)
		player.begin_interaction(anchor, active_sample["location"])
	
	_show_inspection_ui()

func close_inspection() -> void:
	if not is_inspecting:
		return
	is_inspecting = false
	if _inspection_ui:
		_inspection_ui.queue_free()
		_inspection_ui = null
	
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("end_interaction"):
		player.end_interaction()
	if player and player.has_method("capture_mouse"):
		player.capture_mouse()
	
	inspection_ended.emit()

func _show_inspection_ui() -> void:
	if _inspection_ui:
		_inspection_ui.queue_free()
	
	_inspection_ui = CanvasLayer.new()
	_inspection_ui.layer = 25
	add_child(_inspection_ui)
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# Full-screen translucent container
	var root_ctrl = Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	_inspection_ui.add_child(root_ctrl)
	
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = AerospaceTheme.COLOR_BG_DARK
	root_ctrl.add_child(bg)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.add_child(center)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 520)
	var sb = AerospaceTheme.create_glass_panel_style("res://textures/ui/sci_fi_glass_panel.png", 28)
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)
	
	# Header
	var tag = Label.new()
	tag.text = "// NASA LUNAR SAMPLE CURATION ARCHIVE — APOLLO 17 //"
	tag.modulate = AerospaceTheme.COLOR_CYAN
	tag.add_theme_font_size_override("font_size", 13)
	vbox.add_child(tag)
	
	var title = Label.new()
	title.text = active_sample.get("name", "Lunar Sample")
	title.add_theme_font_size_override("font_size", 22)
	title.modulate = AerospaceTheme.COLOR_TEXT_PRIMARY
	vbox.add_child(title)
	
	var sep1 = HSeparator.new()
	vbox.add_child(sep1)
	
	# Metadata Grid
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)
	
	_add_grid_row(grid, "Sample Identifier:", active_sample.get("id", ""))
	_add_grid_row(grid, "Collection Site:", active_sample.get("station", ""))
	_add_grid_row(grid, "Radiometric Age:", active_sample.get("age", ""))
	_add_grid_row(grid, "Petrological Classification:", active_sample.get("petrology", ""))
	
	var sep2 = HSeparator.new()
	vbox.add_child(sep2)
	
	# Mineral composition
	var min_header = Label.new()
	min_header.text = "Mineralogical & Chemical Composition:"
	min_header.modulate = AerospaceTheme.COLOR_AMBER
	min_header.add_theme_font_size_override("font_size", 13)
	vbox.add_child(min_header)
	
	var min_text = Label.new()
	min_text.text = active_sample.get("minerals", "")
	min_text.autowrap_mode = TextServer.AUTOWRAP_WORD
	min_text.modulate = AerospaceTheme.COLOR_TEXT_PRIMARY
	vbox.add_child(min_text)
	
	# Geological Summary
	var desc_header = Label.new()
	desc_header.text = "Scientific Curation Assessment:"
	desc_header.modulate = AerospaceTheme.COLOR_TURQUOISE
	desc_header.add_theme_font_size_override("font_size", 13)
	vbox.add_child(desc_header)
	
	var desc = RichTextLabel.new()
	desc.bbcode_enabled = true
	desc.text = active_sample.get("summary", "")
	desc.custom_minimum_size = Vector2(0, 80)
	vbox.add_child(desc)
	
	# Footer buttons
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_END
	hbox.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox)
	
	var close_btn = Button.new()
	close_btn.text = "[ CLOSE SAMPLE DOSSIER (F / ESC) ]"
	close_btn.custom_minimum_size = Vector2(220, 42)
	close_btn.pressed.connect(close_inspection)
	hbox.add_child(close_btn)

func _add_grid_row(grid: GridContainer, label_str: String, val_str: String) -> void:
	var l = Label.new()
	l.text = label_str
	l.modulate = AerospaceTheme.COLOR_TEXT_SECONDARY
	grid.add_child(l)
	
	var v = Label.new()
	v.text = val_str
	v.modulate = AerospaceTheme.COLOR_CYAN
	grid.add_child(v)
