extends Area3D

# Echoes Beyond Earth - Artifact with full dig/clean discovery sequence

# ---- Existing signals (kept for compatibility) ----
signal artifact_interacted(artifact_id: String)

# ---- New discovery-sequence signals ----
signal dig_started()
signal dig_completed()
signal cleaning_started()
signal cleaning_completed(artifact_id: String)
signal state_changed(new_state: int)

# ---- State machine ----
enum ArtifactState {
	BURIED,       # Only scanner can detect; no visual
	DIG_SITE,     # Player is here; show dig prompt
	DIGGING,      # E held; digging in progress
	EXPOSED,      # Fully dug; show recover prompt
	CLEANING,     # Cleaning UI active
	IDENTIFIED    # Fully recovered and identified
}

# ---- Exports ----
@export var artifact_id: String = "apollo_lrv"
@export var interaction_range: float = 3.5
@export var dig_duration: float = 4.0
@export var clean_duration: float = 7.0

# ---- Onready nodes (must match artifact.tscn) ----
@onready var prompt_label: Label3D = $PromptLabel
@onready var beacon_ring: MeshInstance3D = $BeaconRing
@onready var visual_model: Node3D = $VisualModel
@onready var dust_particles: GPUParticles3D = $DustParticles
@onready var dig_progress_label: Label3D = $DigProgressLabel

# ---- State variables ----
var current_state: ArtifactState = ArtifactState.BURIED
var dig_progress: float = 0.0
var clean_progress: float = 0.0
var is_player_holding_e: bool = false
var dig_particles_active: bool = false

# ---- Internal ----
var is_recovered: bool = false
var artifact_name: String = ""
var _beacon_phase: float = 0.0
var _clean_ui: CanvasLayer = null
var _scanner_ref: Node = null
var _is_player_in_zone: bool = false
var _interacting_player: CharacterBody3D = null
var _excavation_pit: Node3D = null
var _glint_effect: Node3D = null
var _excavation_menu: CanvasLayer = null
var is_anomaly_confirmed: bool = false

func _get_player() -> CharacterBody3D:
	if _interacting_player and is_instance_valid(_interacting_player):
		return _interacting_player
	return get_tree().get_first_node_in_group("player") as CharacterBody3D

func get_interaction_anchor(player_pos: Vector3) -> Vector3:
	var diff = player_pos - global_position
	diff.y = 0.0
	var dist = diff.length()
	var dir = diff.normalized() if dist > 0.1 else Vector3(0, 0, 1.8)
	var anchor = global_position + dir * 1.8
	anchor.y = player_pos.y
	return anchor

# ---- Public interface (kept for scanner & game_state compatibility) ----
func get_artifact_id() -> String:
	return artifact_id

func get_world_position() -> Vector3:
	return global_position

func _ready() -> void:
	add_to_group("artifacts")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# Permanently hide artificial yellow ring and floating markers
	if beacon_ring:
		beacon_ring.visible = false
	if prompt_label:
		prompt_label.visible = false
	
	# Initialize realistic stratified excavation pit & spoil pile
	var pit_script = load("res://scripts/environment/lunar_excavation_pit.gd")
	if pit_script:
		_excavation_pit = Node3D.new()
		_excavation_pit.name = "LunarExcavationPit"
		_excavation_pit.set_script(pit_script)
		add_child(_excavation_pit)
	
	# Initialize natural organic glittering ground shimmer
	var is_metal = true
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		var data = game_state.get_artifact_data(artifact_id)
		var cat = data.get("category", "")
		if (cat == "Natural Lunar Material" or cat == "Natural Martian Material" or cat == "Scientific Discoveries") and artifact_id != "lunar_iron_meteorite":
			is_metal = false
	
	var glint_script = load("res://scripts/environment/lunar_glint_effect.gd")
	if glint_script:
		_glint_effect = Node3D.new()
		_glint_effect.set_script(glint_script)
		_glint_effect.name = "LunarGlintEffect"
		_glint_effect.is_metallic = is_metal
		add_child(_glint_effect)
	
	_load_artifact_metadata()
	_update_visual_representation()
	_update_state_from_gamestate()
	_update_state_visuals()
	
	# Configure dust particles
	_setup_dust_particles()
	
	# Listen for future recovery signals from game_state
	if game_state:
		game_state.artifact_recovered.connect(_on_artifact_recovered_globally)
	
	# Connect to scanner's locked_on_location signal
	call_deferred("_connect_to_scanner")

func _connect_to_scanner() -> void:
	var scanner = get_tree().get_first_node_in_group("scanner")
	if scanner:
		_scanner_ref = scanner
		if scanner.has_signal("locked_on_location"):
			scanner.locked_on_location.connect(_on_scanner_locked_on)
		if scanner.has_signal("left_location"):
			scanner.left_location.connect(_on_scanner_left)

func _setup_dust_particles() -> void:
	if not dust_particles:
		return
	var pm = ParticleProcessMaterial.new()
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0
	pm.gravity = Vector3(0, -1.62, 0)
	pm.initial_velocity_min = 0.3
	pm.initial_velocity_max = 0.5
	pm.scale_min = 0.03
	pm.scale_max = 0.06
	pm.color = Color(0.65, 0.6, 0.5, 0.8)
	dust_particles.process_material = pm
	dust_particles.amount = 24
	dust_particles.lifetime = 1.2
	dust_particles.emitting = false

func _load_artifact_metadata() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		var data = game_state.get_artifact_data(artifact_id)
		if not data.is_empty():
			artifact_name = data.get("name", artifact_id)
		else:
			artifact_name = artifact_id.capitalize()
	else:
		artifact_name = artifact_id.capitalize()

func _update_state_from_gamestate() -> void:
	var game_state = get_node_or_null("/root/GameState")
	if game_state and game_state.is_artifact_recovered(artifact_id):
		current_state = ArtifactState.IDENTIFIED
		is_recovered = true

func _on_artifact_recovered_globally(recovered_id: String) -> void:
	if recovered_id == artifact_id and current_state != ArtifactState.IDENTIFIED:
		current_state = ArtifactState.IDENTIFIED
		is_recovered = true
		_update_state_visuals()

# ---- Scanner event handlers ----
func _on_scanner_locked_on() -> void:
	# Only respond if buried and scanner's current closest is this artifact
	if current_state != ArtifactState.BURIED:
		return
	if not _scanner_ref:
		_scanner_ref = get_tree().get_first_node_in_group("scanner")
	if _scanner_ref and _scanner_ref.get_current_target() == artifact_id:
		_set_state(ArtifactState.DIG_SITE)

func _on_scanner_left() -> void:
	# If we were in DIG_SITE but player moved away (via scanner leaving)
	if current_state == ArtifactState.DIG_SITE:
		_set_state(ArtifactState.BURIED)

# ---- Body enter/exit ----
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_is_player_in_zone = true
		_interacting_player = body as CharacterBody3D
		if current_state == ArtifactState.BURIED:
			_set_state(ArtifactState.DIG_SITE)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_is_player_in_zone = false
		is_anomaly_confirmed = false
		_close_excavation_menu()
		if current_state == ArtifactState.DIG_SITE:
			_set_state(ArtifactState.BURIED)
		elif current_state == ArtifactState.DIGGING:
			_cancel_digging()
		_interacting_player = null

# ---- State machine ----
func _set_state(new_state: ArtifactState) -> void:
	current_state = new_state
	state_changed.emit(new_state)
	_update_state_visuals()

func _update_state_visuals() -> void:
	if beacon_ring:
		beacon_ring.visible = false
	
	if not visual_model:
		return
	
	match current_state:
		ArtifactState.BURIED:
			visual_model.visible = false
			if prompt_label:
				prompt_label.visible = false
			if dig_progress_label:
				dig_progress_label.visible = false
		
		ArtifactState.DIG_SITE:
			visual_model.visible = false
			# Handled by minimalist excavation direction menu upon metal detector confirmation
			if prompt_label:
				prompt_label.visible = false
			if dig_progress_label:
				dig_progress_label.visible = false
		
		ArtifactState.DIGGING:
			visual_model.visible = false
			if prompt_label:
				prompt_label.visible = false
			if dig_progress_label:
				dig_progress_label.visible = true
				dig_progress_label.text = "Excavating [Layer 1: Loose Regolith]... 0%"
		
		ArtifactState.EXPOSED:
			visual_model.visible = true
			visual_model.scale = Vector3.ONE
			if prompt_label:
				prompt_label.text = "[E] DELICATE BRUSHING & SAMPLE RECOVERY"
				prompt_label.modulate = Color(0.85, 0.95, 1.0, 0.9)
				prompt_label.visible = true
			if dig_progress_label:
				dig_progress_label.visible = false
		
		ArtifactState.CLEANING:
			visual_model.visible = true
			if prompt_label:
				prompt_label.visible = false
			if dig_progress_label:
				dig_progress_label.visible = false
		
		ArtifactState.IDENTIFIED:
			visual_model.visible = true
			visual_model.scale = Vector3.ONE
			if prompt_label:
				prompt_label.text = "[IDENTIFIED] " + artifact_name
				prompt_label.modulate = Color(0.4, 1.0, 0.5, 0.8)
				prompt_label.visible = true
			if dig_progress_label:
				dig_progress_label.visible = false
			is_recovered = true

func _set_beacon_color(albedo: Color, emission: Color) -> void:
	if not beacon_ring:
		return
	var mat = beacon_ring.get_active_material(0)
	if mat is StandardMaterial3D:
		mat = mat.duplicate()
		mat.albedo_color = albedo
		mat.emission = emission
		beacon_ring.set_surface_override_material(0, mat)

# ---- Process ----
func _process(delta: float) -> void:
	# Keep artificial yellow rings permanently disabled
	if beacon_ring and beacon_ring.visible:
		beacon_ring.visible = false
	
	# Update natural organic glint effect on regolith
	if _glint_effect and _glint_effect.has_method("set_excavation_progress"):
		_glint_effect.set_excavation_progress(dig_progress)

	# Approach & Metal Detector Confirmation Check in DIG_SITE
	if current_state == ArtifactState.DIG_SITE:
		var player = _get_player()
		if player:
			var coil_pos = player.global_position
			var md = player.get_node_or_null("Visuals/Torso/RightArm/LunarMetalDetector")
			if md and md.has_method("get_coil_global_position"):
				coil_pos = md.get_coil_global_position()
			
			var dist = coil_pos.distance_to(global_position)
			if dist <= 3.2 and not is_anomaly_confirmed:
				_confirm_anomaly_site()
			elif dist > 4.2 and is_anomaly_confirmed:
				is_anomaly_confirmed = false
				_close_excavation_menu()
	
	# Digging progress & soil displacement
	if current_state == ArtifactState.DIGGING:
		if is_player_holding_e:
			dig_progress += delta / dig_duration
			dig_progress = clampf(dig_progress, 0.0, 1.0)
			
			if _excavation_pit and _excavation_pit.has_method("set_progress"):
				_excavation_pit.set_progress(dig_progress)
			
			if _glint_effect and _glint_effect.has_method("set_excavation_progress"):
				_glint_effect.set_excavation_progress(dig_progress)
			
			# Stratified excavation label showing authentic geological layer
			if dig_progress_label:
				var layer_desc = "Layer 1: Loose Regolith"
				if dig_progress > 0.65:
					layer_desc = "Layer 3: Impact Breccia Clasts"
				elif dig_progress > 0.30:
					layer_desc = "Layer 2: Compacted Agglutinates"
				dig_progress_label.text = "Excavating [%s]... %d%%" % [layer_desc, int(dig_progress * 100.0)]
			
			# Progressively reveal visual model inside the pit
			if dig_progress >= 0.25 and not visual_model.visible:
				visual_model.visible = true
			if visual_model.visible:
				var reveal_scale = clampf(remap(dig_progress, 0.25, 1.0, 0.35, 1.0), 0.35, 1.0)
				visual_model.scale = Vector3.ONE * reveal_scale
				visual_model.position.y = lerp(-0.25, 0.0, clampf((dig_progress - 0.3) / 0.7, 0.0, 1.0))
			
			# Subtle regolith dust displacement
			if dust_particles and not dust_particles.emitting:
				dust_particles.emitting = true
			
			var player = _get_player()
			if player and player.has_method("emit_dig_dust"):
				player.emit_dig_dust(global_position)
			
			if dig_progress >= 1.0:
				_complete_digging()
		else:
			# Pause digging: stop particles
			if dust_particles and dust_particles.emitting:
				dust_particles.emitting = false

# ---- Input ----
func _unhandled_input(event: InputEvent) -> void:
	if not _is_player_in_zone and current_state != ArtifactState.CLEANING:
		return
	
	if event.is_action_pressed("interact"):
		is_player_holding_e = true
		match current_state:
			ArtifactState.DIG_SITE:
				_start_digging()
			ArtifactState.EXPOSED:
				_start_cleaning()
	elif event.is_action_released("interact"):
		is_player_holding_e = false
		if current_state == ArtifactState.DIGGING:
			_pause_digging()

func _start_digging() -> void:
	_close_excavation_menu()
	_set_state(ArtifactState.DIGGING)
	dig_started.emit()
	if _excavation_pit and _excavation_pit.has_method("set_marker_visible"):
		_excavation_pit.set_marker_visible(true)
	var player = _get_player()
	if player:
		if player.has_method("set_active_tool"):
			player.set_active_tool(1) # LUNAR SCOOP
		if player.has_method("begin_interaction"):
			var anchor = get_interaction_anchor(player.global_position)
			player.begin_interaction(anchor, global_position)

func _pause_digging() -> void:
	if dust_particles and dust_particles.emitting:
		dust_particles.emitting = false
	var player = _get_player()
	if player:
		if player.has_method("set_active_tool"):
			player.set_active_tool(0) # RETURN TO DETECTOR
		if player.has_method("end_interaction"):
			player.end_interaction()

func _cancel_digging() -> void:
	is_player_holding_e = false
	_close_excavation_menu()
	if dust_particles and dust_particles.emitting:
		dust_particles.emitting = false
	var player = _get_player()
	if player:
		if player.has_method("set_active_tool"):
			player.set_active_tool(0)
		if player.has_method("end_interaction"):
			player.end_interaction()
	_set_state(ArtifactState.BURIED)

# ---- Dig completion ----
func _complete_digging() -> void:
	dig_progress = 1.0
	_close_excavation_menu()
	if _glint_effect:
		_glint_effect.visible = false
	if _excavation_pit and _excavation_pit.has_method("set_progress"):
		_excavation_pit.set_progress(1.0)
	if dust_particles:
		dust_particles.emitting = false
	dig_completed.emit()
	_set_state(ArtifactState.EXPOSED)
	var player = _get_player()
	if player:
		if player.has_method("set_active_tool"):
			player.set_active_tool(2) # GEOLOGICAL BRUSH
		if player.has_method("end_interaction"):
			player.end_interaction()

func _confirm_anomaly_site() -> void:
	if is_anomaly_confirmed:
		return
	is_anomaly_confirmed = true
	_show_excavation_menu()

func _show_excavation_menu() -> void:
	if _excavation_menu or current_state != ArtifactState.DIG_SITE:
		return
	var menu_script = load("res://scripts/ui/excavation_menu.gd")
	if not menu_script:
		return
	
	_excavation_menu = CanvasLayer.new()
	_excavation_menu.set_script(menu_script)
	
	var depth = 14.0
	var sig = "Conductive Metal"
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		var data = game_state.get_artifact_data(artifact_id)
		depth = data.get("discovery_depth_cm", 14.0)
		sig = data.get("detection_signature", "Conductive Metal")
	
	_excavation_menu.set_anomaly_details(artifact_name, depth, sig)
	_excavation_menu.begin_excavation_requested.connect(_on_menu_begin_excavation)
	_excavation_menu.inspect_signal_requested.connect(_on_menu_inspect_signal)
	_excavation_menu.menu_cancelled.connect(_on_menu_cancelled)
	add_child(_excavation_menu)

func _close_excavation_menu() -> void:
	if _excavation_menu:
		_excavation_menu.queue_free()
		_excavation_menu = null

func _on_menu_begin_excavation() -> void:
	_excavation_menu = null
	_start_digging()

func _on_menu_inspect_signal() -> void:
	print("[Prospecting] Anomaly signal verified for: ", artifact_name)
	_show_excavation_menu()

func _on_menu_cancelled() -> void:
	_excavation_menu = null

# ---- Cleaning UI ----
func _start_cleaning() -> void:
	cleaning_started.emit()
	_set_state(ArtifactState.CLEANING)
	var player = _get_player()
	if player:
		if player.has_method("set_active_tool"):
			player.set_active_tool(2) # GEOLOGICAL BRUSH
		if player.has_method("begin_interaction"):
			var anchor = get_interaction_anchor(player.global_position)
			player.begin_interaction(anchor, global_position)
	_start_cleaning_ui()

func _start_cleaning_ui() -> void:
	# Load and instantiate the cleaning UI
	var ui_scene = load("res://scenes/ui/dig_clean_ui.tscn")
	if not ui_scene:
		# Fallback: auto-complete cleaning if scene not found
		call_deferred("on_cleaning_done", artifact_id)
		return
	_clean_ui = ui_scene.instantiate()
	_clean_ui.artifact_id = artifact_id
	_clean_ui.clean_duration = clean_duration
	if _clean_ui.has_signal("cleaning_done"):
		_clean_ui.cleaning_done.connect(on_cleaning_done)
	add_child(_clean_ui)

func on_cleaning_done(done_artifact_id: String) -> void:
	if _clean_ui:
		_clean_ui.queue_free()
		_clean_ui = null
	
	var player = _get_player()
	if player and player.has_method("set_active_tool"):
		player.set_active_tool(3) # SAMPLE CONTAINER
	
	_open_scientific_examination()

func _open_scientific_examination() -> void:
	var exam_script = load("res://scripts/ui/scientific_examination_panel.gd")
	if not exam_script:
		_identify_artifact()
		var player = _get_player()
		if player and player.has_method("end_interaction"):
			player.end_interaction()
		if player and player.has_method("set_active_tool"):
			player.set_active_tool(0)
		return
	
	var panel = CanvasLayer.new()
	panel.set_script(exam_script)
	panel.artifact_id = artifact_id
	panel.documentation_closed.connect(_on_documentation_closed)
	add_child(panel)

func _on_documentation_closed(done_id: String) -> void:
	_identify_artifact()
	var player = _get_player()
	if player and player.has_method("end_interaction"):
		player.end_interaction()
	if player and player.has_method("set_active_tool"):
		player.set_active_tool(0) # RETURN TO DETECTOR
	if player and player.has_method("capture_mouse"):
		player.capture_mouse()

func _identify_artifact() -> void:
	_set_state(ArtifactState.IDENTIFIED)
	var game_state = get_node_or_null("/root/GameState")
	if game_state:
		game_state.register_artifact(artifact_id)
	cleaning_completed.emit(artifact_id)
	artifact_interacted.emit(artifact_id)

# ---- Visual representation (all existing mesh builders kept intact) ----
func set_recovered_visuals() -> void:
	is_recovered = true
	current_state = ArtifactState.IDENTIFIED
	_update_state_visuals()

func _update_visual_representation() -> void:
	if not visual_model:
		return
	
	# Clear any previous child geometry
	for c in visual_model.get_children():
		c.queue_free()
	
	# Generate stylized 3D geometry corresponding to the artifact ID
	match artifact_id:
		"apollo_lrv":
			_build_lrv_mesh()
		"apollo_lm_descent_stage":
			_build_lm_descent_mesh()
		"alsep":
			_build_alsep_mesh()
		"sojourner":
			_build_sojourner_mesh()
		"opportunity":
			_build_opportunity_mesh()
		"ingenuity":
			_build_ingenuity_mesh()
		"lunar_ferroan_anorthosite":
			_build_anorthosite_mesh()
		"lunar_iron_meteorite":
			_build_iron_meteorite_mesh()
		"pyroclastic_orange_glass":
			_build_orange_glass_mesh()
		"apollo_cable_bracket":
			_build_bracket_mesh()
		"jezero_delta_clay":
			_build_jezero_clay_mesh()
		"seitah_olivine_basalt":
			_build_seitah_basalt_mesh()
		"perseverance_heatshield_remnant":
			_build_heatshield_remnant_mesh()
		"martian_meteorite_shergottite":
			_build_martian_meteorite_mesh()
		_:
			_build_default_mesh()

func _build_lrv_mesh() -> void:
	# Stylized Lunar Roving Vehicle
	var chassis = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.8, 0.35, 1.1)
	chassis.mesh = box
	chassis.position = Vector3(0, 0.45, 0)
	var white_mat = StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.9, 0.9, 0.95)
	chassis.set_surface_override_material(0, white_mat)
	visual_model.add_child(chassis)
	
	# Seats
	var seat = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.5, 0.4, 0.8)
	seat.mesh = s_box
	seat.position = Vector3(-0.2, 0.7, 0)
	visual_model.add_child(seat)
	
	# Antenna Dish
	var antenna = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = 0.35
	cyl.bottom_radius = 0.05
	cyl.height = 0.2
	antenna.mesh = cyl
	antenna.position = Vector3(0.6, 1.0, 0)
	antenna.rotation_degrees = Vector3(25, 0, 45)
	visual_model.add_child(antenna)
	
	# 4 Wire-mesh wheels
	var wheel_mat = StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.3, 0.32, 0.35)
	var wheel_offsets = [
		Vector3(-0.7, 0.3, -0.65), Vector3(0.7, 0.3, -0.65),
		Vector3(-0.7, 0.3, 0.65), Vector3(0.7, 0.3, 0.65)
	]
	for off in wheel_offsets:
		var wheel = MeshInstance3D.new()
		var w_cyl = CylinderMesh.new()
		w_cyl.top_radius = 0.3
		w_cyl.bottom_radius = 0.3
		w_cyl.height = 0.2
		wheel.mesh = w_cyl
		wheel.rotation_degrees = Vector3(90, 0, 0)
		wheel.position = off
		wheel.set_surface_override_material(0, wheel_mat)
		visual_model.add_child(wheel)

func _build_lm_descent_mesh() -> void:
	# Gold foil octagonal descent stage
	var body = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.radial_segments = 8
	cyl.top_radius = 1.3
	cyl.bottom_radius = 1.4
	cyl.height = 0.9
	body.mesh = cyl
	body.position = Vector3(0, 0.65, 0)
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.95, 0.78, 0.2)
	gold_mat.metallic = 0.85
	gold_mat.roughness = 0.25
	body.set_surface_override_material(0, gold_mat)
	visual_model.add_child(body)
	
	# Central Rocket Nozzle
	var nozzle = MeshInstance3D.new()
	var n_cyl = CylinderMesh.new()
	n_cyl.top_radius = 0.25
	n_cyl.bottom_radius = 0.45
	n_cyl.height = 0.4
	nozzle.mesh = n_cyl
	nozzle.position = Vector3(0, 0.2, 0)
	var dark_mat = StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.15, 0.15, 0.18)
	nozzle.set_surface_override_material(0, dark_mat)
	visual_model.add_child(nozzle)
	
	# 4 Landing Legs
	var leg_mat = StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.85, 0.85, 0.9)
	var leg_angles = [45, 135, 225, 315]
	for a in leg_angles:
		var rad = deg_to_rad(a)
		var leg = MeshInstance3D.new()
		var l_box = BoxMesh.new()
		l_box.size = Vector3(0.15, 0.15, 1.4)
		leg.mesh = l_box
		leg.position = Vector3(sin(rad) * 1.5, 0.35, cos(rad) * 1.5)
		leg.rotation.y = rad
		leg.rotation.x = deg_to_rad(30)
		leg.set_surface_override_material(0, leg_mat)
		visual_model.add_child(leg)
		
		# Footpad
		var pad = MeshInstance3D.new()
		var p_cyl = CylinderMesh.new()
		p_cyl.top_radius = 0.25
		p_cyl.bottom_radius = 0.25
		p_cyl.height = 0.06
		pad.mesh = p_cyl
		pad.position = Vector3(sin(rad) * 2.1, 0.03, cos(rad) * 2.1)
		pad.set_surface_override_material(0, gold_mat)
		visual_model.add_child(pad)

func _build_alsep_mesh() -> void:
	# Central station box
	var station = MeshInstance3D.new()
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.7, 0.6, 0.7)
	station.mesh = s_box
	station.position = Vector3(0, 0.3, 0)
	var white_mat = StandardMaterial3D.new()
	white_mat.albedo_color = Color(0.92, 0.92, 0.95)
	station.set_surface_override_material(0, white_mat)
	visual_model.add_child(station)
	
	# RTG Power cask (cylinder with cooling fins)
	var rtg = MeshInstance3D.new()
	var r_cyl = CylinderMesh.new()
	r_cyl.radial_segments = 12
	r_cyl.top_radius = 0.2
	r_cyl.bottom_radius = 0.2
	r_cyl.height = 0.5
	rtg.mesh = r_cyl
	rtg.position = Vector3(0.7, 0.25, 0.3)
	var rtg_mat = StandardMaterial3D.new()
	rtg_mat.albedo_color = Color(0.4, 0.42, 0.45)
	rtg_mat.metallic = 0.5
	rtg.set_surface_override_material(0, rtg_mat)
	visual_model.add_child(rtg)
	
	# Helical Antenna Mast
	var antenna = MeshInstance3D.new()
	var a_cyl = CylinderMesh.new()
	a_cyl.top_radius = 0.03
	a_cyl.bottom_radius = 0.03
	a_cyl.height = 1.0
	antenna.mesh = a_cyl
	antenna.position = Vector3(0, 0.9, 0)
	visual_model.add_child(antenna)

func _build_sojourner_mesh() -> void:
	# Compact 6-wheel rover body
	var body = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.65, 0.28, 0.45)
	body.mesh = b_box
	body.position = Vector3(0, 0.3, 0)
	var solar_mat = StandardMaterial3D.new()
	solar_mat.albedo_color = Color(0.1, 0.15, 0.35)
	solar_mat.metallic = 0.6
	solar_mat.roughness = 0.2
	body.set_surface_override_material(0, solar_mat)
	visual_model.add_child(body)
	
	# 6 small metal wheels
	var wheel_mat = StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.75, 0.75, 0.8)
	wheel_mat.metallic = 0.8
	var x_coords = [-0.25, 0.0, 0.25]
	for x in x_coords:
		for z in [-0.28, 0.28]:
			var w = MeshInstance3D.new()
			var c = CylinderMesh.new()
			c.top_radius = 0.1
			c.bottom_radius = 0.1
			c.height = 0.08
			w.mesh = c
			w.rotation_degrees = Vector3(90, 0, 0)
			w.position = Vector3(x, 0.12, z)
			w.set_surface_override_material(0, wheel_mat)
			visual_model.add_child(w)

func _build_opportunity_mesh() -> void:
	# MER Opportunity Body & Solar Panels
	var body = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(1.2, 0.4, 0.9)
	body.mesh = b_box
	body.position = Vector3(0, 0.5, 0)
	var solar_mat = StandardMaterial3D.new()
	solar_mat.albedo_color = Color(0.08, 0.12, 0.32)
	body.set_surface_override_material(0, solar_mat)
	visual_model.add_child(body)
	
	# Pancam Mast
	var mast = MeshInstance3D.new()
	var m_cyl = CylinderMesh.new()
	m_cyl.top_radius = 0.04
	m_cyl.bottom_radius = 0.04
	m_cyl.height = 0.9
	mast.mesh = m_cyl
	mast.position = Vector3(0.4, 1.1, 0)
	visual_model.add_child(mast)
	
	# Camera Head
	var head = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.2, 0.12, 0.3)
	head.mesh = h_box
	head.position = Vector3(0.4, 1.55, 0)
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.9, 0.7, 0.2)
	head.set_surface_override_material(0, gold_mat)
	visual_model.add_child(head)
	
	# 6 Wheels
	var wheel_mat = StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.3, 0.3, 0.35)
	for x in [-0.5, 0.0, 0.5]:
		for z in [-0.55, 0.55]:
			var w = MeshInstance3D.new()
			var c = CylinderMesh.new()
			c.top_radius = 0.18
			c.bottom_radius = 0.18
			c.height = 0.12
			w.mesh = c
			w.rotation_degrees = Vector3(90, 0, 0)
			w.position = Vector3(x, 0.2, z)
			w.set_surface_override_material(0, wheel_mat)
			visual_model.add_child(w)

func _build_ingenuity_mesh() -> void:
	# Fuselage body
	var body = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.3, 0.3, 0.3)
	body.mesh = b_box
	body.position = Vector3(0, 0.45, 0)
	var gold_mat = StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.9, 0.75, 0.2)
	gold_mat.metallic = 0.8
	body.set_surface_override_material(0, gold_mat)
	visual_model.add_child(body)
	
	# Rotor Mast
	var mast = MeshInstance3D.new()
	var m_cyl = CylinderMesh.new()
	m_cyl.top_radius = 0.02
	m_cyl.bottom_radius = 0.02
	m_cyl.height = 0.6
	mast.mesh = m_cyl
	mast.position = Vector3(0, 0.75, 0)
	visual_model.add_child(mast)
	
	# 2 Counter-rotating carbon fiber rotor blades
	var rotor_mat = StandardMaterial3D.new()
	rotor_mat.albedo_color = Color(0.12, 0.12, 0.14)
	
	var rotor1 = MeshInstance3D.new()
	var r_box1 = BoxMesh.new()
	r_box1.size = Vector3(1.2, 0.02, 0.08)
	rotor1.mesh = r_box1
	rotor1.position = Vector3(0, 0.85, 0)
	rotor1.set_surface_override_material(0, rotor_mat)
	visual_model.add_child(rotor1)
	
	var rotor2 = MeshInstance3D.new()
	var r_box2 = BoxMesh.new()
	r_box2.size = Vector3(1.2, 0.02, 0.08)
	rotor2.mesh = r_box2
	rotor2.position = Vector3(0, 0.95, 0)
	rotor2.rotation_degrees = Vector3(0, 90, 0)
	rotor2.set_surface_override_material(0, rotor_mat)
	visual_model.add_child(rotor2)
	
	# 4 Spindly Carbon Legs
	for a in [45, 135, 225, 315]:
		var rad = deg_to_rad(a)
		var leg = MeshInstance3D.new()
		var l_box = BoxMesh.new()
		l_box.size = Vector3(0.04, 0.04, 0.6)
		leg.mesh = l_box
		leg.position = Vector3(sin(rad) * 0.25, 0.2, cos(rad) * 0.25)
		leg.rotation.y = rad
		leg.rotation.x = deg_to_rad(40)
		leg.set_surface_override_material(0, rotor_mat)
		visual_model.add_child(leg)

func _build_default_mesh() -> void:
	var box = MeshInstance3D.new()
	var b = BoxMesh.new()
	b.size = Vector3(0.8, 0.8, 0.8)
	box.mesh = b
	box.position = Vector3(0, 0.4, 0)
	visual_model.add_child(box)

func _build_anorthosite_mesh() -> void:
	var rock = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.26
	sphere.height = 0.42
	sphere.radial_segments = 12
	sphere.rings = 6
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.86, 0.88, 0.90) # Plagioclase feldspar anorthosite white
	mat.roughness = 0.92
	sphere.material = mat
	rock.mesh = sphere
	rock.position = Vector3(0, 0.15, 0)
	visual_model.add_child(rock)

	# Dark pyroxene crystal facets
	for i in range(4):
		var facet = MeshInstance3D.new()
		var f_mesh = BoxMesh.new()
		f_mesh.size = Vector3(0.08, 0.06, 0.08)
		var f_mat = StandardMaterial3D.new()
		f_mat.albedo_color = Color(0.18, 0.22, 0.19)
		f_mat.roughness = 0.8
		f_mesh.material = f_mat
		facet.mesh = f_mesh
		var a = i * 1.57
		facet.position = Vector3(cos(a) * 0.18, 0.15 + sin(a) * 0.08, sin(a) * 0.18)
		visual_model.add_child(facet)

func _build_iron_meteorite_mesh() -> void:
	var meteor = MeshInstance3D.new()
	var m_mesh = SphereMesh.new()
	m_mesh.radius = 0.20
	m_mesh.height = 0.32
	m_mesh.radial_segments = 10
	m_mesh.rings = 5
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.32, 0.33, 0.35)
	mat.metallic = 0.92
	mat.roughness = 0.38
	m_mesh.material = mat
	meteor.mesh = m_mesh
	meteor.position = Vector3(0, 0.12, 0)
	visual_model.add_child(meteor)

	# Metallic thumbprint / regmaglypt depressions
	for i in range(3):
		var pit = MeshInstance3D.new()
		var p_mesh = SphereMesh.new()
		p_mesh.radius = 0.08
		p_mesh.height = 0.06
		var p_mat = StandardMaterial3D.new()
		p_mat.albedo_color = Color(0.24, 0.25, 0.28)
		p_mat.metallic = 0.95
		p_mat.roughness = 0.25
		p_mesh.material = p_mat
		pit.mesh = p_mesh
		pit.position = Vector3(cos(i * 2.0) * 0.14, 0.12, sin(i * 2.0) * 0.14)
		visual_model.add_child(pit)

func _build_orange_glass_mesh() -> void:
	# Apollo core sample drive tube
	var tube = MeshInstance3D.new()
	var t_mesh = CylinderMesh.new()
	t_mesh.top_radius = 0.05
	t_mesh.bottom_radius = 0.05
	t_mesh.height = 0.55
	var t_mat = StandardMaterial3D.new()
	t_mat.albedo_color = Color(0.85, 0.86, 0.88)
	t_mat.metallic = 0.85
	t_mat.roughness = 0.25
	t_mesh.material = t_mat
	tube.mesh = t_mesh
	tube.position = Vector3(0, 0.22, 0)
	tube.rotation.z = deg_to_rad(65.0)
	visual_model.add_child(tube)

	# Exposed core section showing brilliant pyroclastic orange glass beads
	var glass = MeshInstance3D.new()
	var g_mesh = CylinderMesh.new()
	g_mesh.top_radius = 0.046
	g_mesh.bottom_radius = 0.046
	g_mesh.height = 0.32
	var g_mat = StandardMaterial3D.new()
	g_mat.albedo_color = Color(1.0, 0.50, 0.06) # Vibrant Apollo 17 orange soil
	g_mat.roughness = 0.35
	g_mat.metallic = 0.1
	glass.mesh = g_mesh
	glass.position = Vector3(0, 0.22, 0)
	glass.rotation.z = deg_to_rad(65.0)
	visual_model.add_child(glass)

func _build_bracket_mesh() -> void:
	var bracket = MeshInstance3D.new()
	var b_mesh = BoxMesh.new()
	b_mesh.size = Vector3(0.32, 0.12, 0.22)
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.82, 0.84, 0.86) # Anodized Aluminum 6061-T6
	mat.metallic = 0.88
	mat.roughness = 0.3
	b_mesh.material = mat
	bracket.mesh = b_mesh
	bracket.position = Vector3(0, 0.10, 0)
	visual_model.add_child(bracket)

	# Mounting holes and cable clamp
	var clamp_bar = MeshInstance3D.new()
	var c_mesh = BoxMesh.new()
	c_mesh.size = Vector3(0.06, 0.08, 0.26)
	clamp_bar.mesh = c_mesh
	clamp_bar.position = Vector3(0, 0.18, 0)
	visual_model.add_child(clamp_bar)

func _build_jezero_clay_mesh() -> void:
	# Stratified sedimentary delta mudstone sample with distinct fine bedding laminations
	var base_rock = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.38, 0.16, 0.28)
	var mat_clay = StandardMaterial3D.new()
	mat_clay.albedo_color = Color(0.60, 0.52, 0.42) # Tan/beige smectite-bearing mudstone
	mat_clay.roughness = 0.94
	b_box.material = mat_clay
	base_rock.mesh = b_box
	base_rock.position = Vector3(0, 0.10, 0)
	visual_model.add_child(base_rock)

	# Laminated sedimentary bedding layers
	var layer1 = MeshInstance3D.new()
	var l_box1 = BoxMesh.new()
	l_box1.size = Vector3(0.39, 0.03, 0.29)
	var mat_silt = StandardMaterial3D.new()
	mat_silt.albedo_color = Color(0.72, 0.60, 0.48)
	mat_silt.roughness = 0.96
	l_box1.material = mat_silt
	layer1.mesh = l_box1
	layer1.position = Vector3(0, 0.14, 0)
	visual_model.add_child(layer1)

	# Light calcium sulfate evaporite vein
	var vein = MeshInstance3D.new()
	var v_box = BoxMesh.new()
	v_box.size = Vector3(0.36, 0.015, 0.05)
	var mat_vein = StandardMaterial3D.new()
	mat_vein.albedo_color = Color(0.92, 0.90, 0.88) # White gypsum/sulfate mineral filling
	mat_vein.roughness = 0.70
	v_box.material = mat_vein
	vein.mesh = v_box
	vein.position = Vector3(0, 0.18, 0.04)
	visual_model.add_child(vein)

func _build_seitah_basalt_mesh() -> void:
	# Igneous olivine cumulate rock from the Jezero crater floor
	var rock = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.radial_segments = 7
	cyl.top_radius = 0.22
	cyl.bottom_radius = 0.25
	cyl.height = 0.24
	var mat_basalt = StandardMaterial3D.new()
	mat_basalt.albedo_color = Color(0.24, 0.23, 0.21) # Dark basaltic groundmass
	mat_basalt.roughness = 0.88
	cyl.material = mat_basalt
	rock.mesh = cyl
	rock.position = Vector3(0, 0.12, 0)
	rock.rotation_degrees = Vector3(15, 30, -10)
	visual_model.add_child(rock)

	# Distinct green-tinted olivine crystal phenocrysts
	var mat_olivine = StandardMaterial3D.new()
	mat_olivine.albedo_color = Color(0.36, 0.44, 0.26) # Characteristic forsterite/olivine green
	mat_olivine.roughness = 0.45
	mat_olivine.metallic = 0.1
	for i in range(5):
		var crystal = MeshInstance3D.new()
		var c_mesh = BoxMesh.new()
		c_mesh.size = Vector3(0.06, 0.05, 0.06)
		c_mesh.material = mat_olivine
		crystal.mesh = c_mesh
		var a = i * 1.25
		crystal.position = Vector3(cos(a) * 0.16, 0.14 + sin(a) * 0.06, sin(a) * 0.16)
		crystal.rotation_degrees = Vector3(a * 20, a * 45, a * 15)
		visual_model.add_child(crystal)

func _build_heatshield_remnant_mesh() -> void:
	# Curvilinear thermal protection tile with titanium bracket
	var tile = MeshInstance3D.new()
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.48, 0.08, 0.36)
	var mat_tile = StandardMaterial3D.new()
	mat_tile.albedo_color = Color(0.18, 0.16, 0.16) # Charred PICA ablator surface
	mat_tile.roughness = 0.95
	t_box.material = mat_tile
	tile.mesh = t_box
	tile.position = Vector3(0, 0.08, 0)
	tile.rotation_degrees = Vector3(8, -15, 6)
	visual_model.add_child(tile)

	# Lightweight reflective aerospace alloy backing
	var backing = MeshInstance3D.new()
	var b_box = BoxMesh.new()
	b_box.size = Vector3(0.46, 0.02, 0.34)
	var mat_back = StandardMaterial3D.new()
	mat_back.albedo_color = Color(0.85, 0.85, 0.88)
	mat_back.metallic = 0.92
	mat_back.roughness = 0.25
	b_box.material = mat_back
	backing.mesh = b_box
	backing.position = Vector3(0, 0.04, 0)
	tile.add_child(backing)

	# Inconel fastener and serial tag
	var tag = MeshInstance3D.new()
	var tag_mesh = BoxMesh.new()
	tag_mesh.size = Vector3(0.12, 0.01, 0.06)
	var mat_tag = StandardMaterial3D.new()
	mat_tag.albedo_color = Color(0.95, 0.90, 0.40) # Brass/anodized ID plate
	mat_tag.metallic = 0.80
	tag_mesh.material = mat_tag
	tag.mesh = tag_mesh
	tag.position = Vector3(0.12, 0.05, 0.08)
	tile.add_child(tag)

func _build_martian_meteorite_mesh() -> void:
	# Shergottite basaltic meteorite with black fusion crust and shock melt veins
	var rock = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.28
	sphere.radial_segments = 12
	sphere.rings = 6
	var mat_shergottite = StandardMaterial3D.new()
	mat_shergottite.albedo_color = Color(0.28, 0.26, 0.24) # Dark interior pyroxene
	mat_shergottite.roughness = 0.82
	sphere.material = mat_shergottite
	rock.mesh = sphere
	rock.position = Vector3(0, 0.10, 0)
	visual_model.add_child(rock)

	# Glassy shock melt vein
	var vein = MeshInstance3D.new()
	var v_cyl = CylinderMesh.new()
	v_cyl.top_radius = 0.015
	v_cyl.bottom_radius = 0.015
	v_cyl.height = 0.22
	var mat_glass = StandardMaterial3D.new()
	mat_glass.albedo_color = Color(0.08, 0.08, 0.09) # Black impact glass / maskelynite
	mat_glass.roughness = 0.20
	mat_glass.metallic = 0.15
	v_cyl.material = mat_glass
	vein.mesh = v_cyl
	vein.position = Vector3(0.05, 0.10, 0)
	vein.rotation_degrees = Vector3(35, 20, 45)
	visual_model.add_child(vein)
