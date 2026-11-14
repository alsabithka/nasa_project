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

# ---- Public interface (kept for scanner & game_state compatibility) ----
func get_artifact_id() -> String:
	return artifact_id

func get_world_position() -> Vector3:
	return global_position

func _ready() -> void:
	add_to_group("artifacts")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	_load_artifact_metadata()
	_update_visual_representation()
	_update_state_from_gamestate()
	_update_state_visuals()
	
	# Configure dust particles
	_setup_dust_particles()
	
	# Listen for future recovery signals from game_state
	var game_state = get_node_or_null("/root/GameState")
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
	pm.gravity = Vector3(0, -1.5, 0)
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
		return
	# Check that the scanner is targeting us (the scanner's target matches our id)
	if _scanner_ref.get_current_target() == artifact_id:
		_set_state(ArtifactState.DIG_SITE)

func _on_scanner_left() -> void:
	# If we were in DIG_SITE but player moved away (via scanner leaving)
	if current_state == ArtifactState.DIG_SITE:
		_set_state(ArtifactState.BURIED)

# ---- Body enter/exit ----
func _on_body_entered(body: Node3D) -> void:
	pass # state transitions handled by scanner signals and input

func _on_body_exited(body: Node3D) -> void:
	pass

# ---- State machine ----
func _set_state(new_state: ArtifactState) -> void:
	current_state = new_state
	state_changed.emit(new_state)
	_update_state_visuals()

func _update_state_visuals() -> void:
	if not prompt_label or not beacon_ring or not visual_model:
		return
	
	match current_state:
		ArtifactState.BURIED:
			visual_model.visible = false
			prompt_label.visible = false
			if dig_progress_label:
				dig_progress_label.visible = false
			_set_beacon_color(Color(1.0, 0.65, 0.0, 0.7), Color(1.0, 0.5, 0.0))
		
		ArtifactState.DIG_SITE:
			visual_model.visible = false
			prompt_label.text = "[E] DIG HERE - Unidentified Signal Source"
			prompt_label.modulate = Color(1.0, 0.85, 0.2, 1.0)
			prompt_label.visible = true
			if dig_progress_label:
				dig_progress_label.visible = false
			_set_beacon_color(Color(1.0, 0.65, 0.0, 0.9), Color(1.0, 0.6, 0.0))
		
		ArtifactState.DIGGING:
			visual_model.visible = false
			prompt_label.visible = false
			if dig_progress_label:
				dig_progress_label.visible = true
				dig_progress_label.text = "Excavating... 0%"
			_set_beacon_color(Color(1.0, 0.65, 0.0, 0.9), Color(1.0, 0.6, 0.0))
		
		ArtifactState.EXPOSED:
			visual_model.visible = true
			visual_model.scale = Vector3.ONE
			prompt_label.text = "[E] RECOVER OBJECT"
			prompt_label.modulate = Color(0.3, 1.0, 0.5, 1.0)
			prompt_label.visible = true
			if dig_progress_label:
				dig_progress_label.visible = false
			_set_beacon_color(Color(0.2, 0.9, 0.4, 0.7), Color(0.2, 0.9, 0.4))
		
		ArtifactState.CLEANING:
			visual_model.visible = true
			prompt_label.visible = false
			if dig_progress_label:
				dig_progress_label.visible = false
		
		ArtifactState.IDENTIFIED:
			visual_model.visible = true
			visual_model.scale = Vector3.ONE
			prompt_label.text = "[IDENTIFIED] " + artifact_name
			prompt_label.modulate = Color(0.4, 1.0, 0.5, 0.9)
			prompt_label.visible = true
			if dig_progress_label:
				dig_progress_label.visible = false
			_set_beacon_color(Color(0.2, 0.9, 0.4, 0.6), Color(0.2, 0.9, 0.4))
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
	_beacon_phase += delta
	
	# Beacon ring animation
	if beacon_ring:
		beacon_ring.rotate_y(delta * (2.5 if current_state == ArtifactState.DIG_SITE else 0.8))
		match current_state:
			ArtifactState.BURIED, ArtifactState.DIG_SITE:
				var pulse = (sin(_beacon_phase * 3.0) + 1.0) * 0.5
				var spd = 4.0 if current_state == ArtifactState.DIG_SITE else 1.5
				pulse = (sin(_beacon_phase * spd) + 1.0) * 0.5
				beacon_ring.scale = Vector3(1.0 + pulse * 0.2, 1.0, 1.0 + pulse * 0.2)
			ArtifactState.EXPOSED, ArtifactState.IDENTIFIED:
				var pulse = (sin(_beacon_phase * 2.0) + 1.0) * 0.5
				beacon_ring.scale = Vector3(1.0 + pulse * 0.1, 1.0, 1.0 + pulse * 0.1)
			_:
				beacon_ring.scale = Vector3.ONE
	
	# Digging progress
	if current_state == ArtifactState.DIGGING:
		if is_player_holding_e:
			dig_progress += delta / dig_duration
			dig_progress = clamp(dig_progress, 0.0, 1.0)
			
			# Update progress label
			if dig_progress_label:
				dig_progress_label.text = "Excavating... %d%%" % int(dig_progress * 100.0)
			
			# Progressively reveal visual model
			if dig_progress >= 0.3 and not visual_model.visible:
				visual_model.visible = true
			if visual_model.visible:
				var reveal_scale = clamp(remap(dig_progress, 0.3, 1.0, 0.3, 1.0), 0.3, 1.0)
				if dig_progress < 0.3:
					reveal_scale = 0.0
					visual_model.visible = false
				visual_model.scale = Vector3.ONE * reveal_scale
			
			# Activate dust
			if dust_particles and not dust_particles.emitting:
				dust_particles.emitting = true
			
			if dig_progress >= 1.0:
				_complete_digging()
		else:
			# Pause digging: stop particles
			if dust_particles and dust_particles.emitting:
				dust_particles.emitting = false

# ---- Input ----
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		is_player_holding_e = true
		match current_state:
			ArtifactState.DIG_SITE:
				dig_started.emit()
				_set_state(ArtifactState.DIGGING)
			ArtifactState.EXPOSED:
				cleaning_started.emit()
				_set_state(ArtifactState.CLEANING)
				_start_cleaning_ui()
	elif event.is_action_released("interact"):
		is_player_holding_e = false

# ---- Dig completion ----
func _complete_digging() -> void:
	dig_progress = 1.0
	if dust_particles:
		dust_particles.emitting = false
	dig_completed.emit()
	_set_state(ArtifactState.EXPOSED)

# ---- Cleaning UI ----
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
	_identify_artifact()

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
