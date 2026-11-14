extends Node3D

# Echoes Beyond Earth - Realistic Lunar Geological Excavation Pit & Stratification
# Scientifically grounded in NASA Apollo core sample stratigraphy (Apollo 15-17):
# - Layer 1 (0 to 5 cm): Fine powdery loose lunar regolith (albedo 0.42, high porosity)
# - Layer 2 (5 to 18 cm): Compacted dust with micro-impact agglutinates & glassy spherules (albedo 0.35)
# - Layer 3 (18 to 35 cm): Rocky impact melt breccia with angular lithic clasts
# - Layer 4 (35+ cm): Consolidated pre-mare anorthositic / basaltic substratum
# Includes:
# - Deepening excavation trench with stratified cross-section
# - External spoil pile (mound of displaced lunar soil)
# - Calibrated Apollo survey gnomon marker (shadow reference & color bar)

@export var pit_radius: float = 1.1
@export var max_excavation_depth: float = 0.52

var _progress: float = 0.0
var _pit_mesh: MeshInstance3D
var _spoil_pile: MeshInstance3D
var _gnomon_marker: Node3D
var _strat_layers: Array[MeshInstance3D] = []

func _ready() -> void:
	_create_stratified_pit()
	_create_spoil_pile()
	_create_survey_gnomon()
	set_progress(0.0)

# Builds the layered subsurface crater pit
func _create_stratified_pit() -> void:
	var is_mars = false
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.current_planet == "Mars":
		is_mars = true
	elif get_tree() and get_tree().current_scene and "Mars" in get_tree().current_scene.name:
		is_mars = true

	var mat_regolith = StandardMaterial3D.new()
	var mat_agglutinate = StandardMaterial3D.new()
	var mat_breccia = StandardMaterial3D.new()
	var mat_bedrock = StandardMaterial3D.new()

	if is_mars:
		# Layer 1: Loose oxidized ferric dust (0-5 cm)
		mat_regolith.albedo_color = Color(0.72, 0.32, 0.18)
		mat_regolith.roughness = 0.98

		# Layer 2: Compacted sulfate duricrust hardpan (5-15 cm)
		mat_agglutinate.albedo_color = Color(0.62, 0.42, 0.28)
		mat_agglutinate.roughness = 0.94

		# Layer 3: Stratified deltaic smectite clay / siltstone (15-35 cm)
		mat_breccia.albedo_color = Color(0.50, 0.44, 0.36)
		mat_breccia.roughness = 0.90

		# Layer 4: Dense fractured olivine basalt bedrock (35+ cm)
		mat_bedrock.albedo_color = Color(0.22, 0.20, 0.18)
		mat_bedrock.roughness = 0.85
	else:
		# Layer materials matching Apollo lunar soil profiles
		mat_regolith.albedo_color = Color(0.44, 0.45, 0.48)
		mat_regolith.roughness = 0.98

		mat_agglutinate.albedo_color = Color(0.33, 0.34, 0.37)
		mat_agglutinate.roughness = 0.95
		mat_agglutinate.metallic = 0.05

		mat_breccia.albedo_color = Color(0.28, 0.29, 0.31)
		mat_breccia.roughness = 0.90

		mat_bedrock.albedo_color = Color(0.22, 0.23, 0.25)
		mat_bedrock.roughness = 0.85

	# Subsurface excavation container
	var pit_container = Node3D.new()
	pit_container.name = "PitContainer"
	add_child(pit_container)

	# Pit floor
	_pit_mesh = MeshInstance3D.new()
	var cyl = CylinderMesh.new()
	cyl.top_radius = pit_radius * 0.95
	cyl.bottom_radius = pit_radius * 0.75
	cyl.height = 0.08
	cyl.material = mat_bedrock
	_pit_mesh.mesh = cyl
	_pit_mesh.position.y = -0.04
	pit_container.add_child(_pit_mesh)

	# Distinct irregular stratigraphic wall rings
	var layer_mats = [mat_regolith, mat_agglutinate, mat_breccia, mat_bedrock]
	var layer_heights = [0.06, 0.14, 0.16, 0.16]
	var accum_y = 0.0

	for i in range(layer_mats.size()):
		var ring = MeshInstance3D.new()
		ring.name = "StratumLayer_%d" % i
		var tube = TorusMesh.new()
		tube.inner_radius = pit_radius * (0.92 - i * 0.04)
		tube.outer_radius = pit_radius * (1.02 - i * 0.02)
		tube.rings = 20
		tube.ring_segments = 12
		tube.material = layer_mats[i]
		ring.mesh = tube
		ring.scale.y = layer_heights[i] * 3.5
		ring.position.y = -accum_y - (layer_heights[i] * 0.5)
		accum_y += layer_heights[i]
		pit_container.add_child(ring)
		_strat_layers.append(ring)

# Spoil pile: Excavated soil displaced outside the pit
func _create_spoil_pile() -> void:
	_spoil_pile = MeshInstance3D.new()
	_spoil_pile.name = "RegolithSpoilPile"
	var mound = SphereMesh.new()
	mound.radius = 0.65
	mound.height = 0.40
	mound.radial_segments = 16
	mound.rings = 8

	var is_mars = false
	var gs = get_node_or_null("/root/GameState")
	if gs and gs.current_planet == "Mars":
		is_mars = true
	elif get_tree() and get_tree().current_scene and "Mars" in get_tree().current_scene.name:
		is_mars = true

	var spoil_mat = StandardMaterial3D.new()
	if is_mars:
		spoil_mat.albedo_color = Color(0.68, 0.33, 0.20)
	else:
		spoil_mat.albedo_color = Color(0.38, 0.39, 0.42)
	spoil_mat.roughness = 0.98
	mound.material = spoil_mat

	_spoil_pile.mesh = mound
	# Positioned northeast of pit rim
	_spoil_pile.position = Vector3(pit_radius * 1.25, 0.08, -pit_radius * 0.8)
	_spoil_pile.scale = Vector3.ZERO
	add_child(_spoil_pile)

# Apollo Survey Gnomon: Placed at archaeological site to record local vertical, sun angle and color calibration
func _create_survey_gnomon() -> void:
	_gnomon_marker = Node3D.new()
	_gnomon_marker.name = "SurveyGnomon"
	# Positioned at western perimeter
	_gnomon_marker.position = Vector3(-pit_radius * 1.35, 0.0, 0.3)
	
	var mat_metal = StandardMaterial3D.new()
	mat_metal.albedo_color = Color(0.85, 0.86, 0.88)
	mat_metal.metallic = 0.85
	mat_metal.roughness = 0.3

	var mat_orange = StandardMaterial3D.new()
	mat_orange.albedo_color = Color(1.0, 0.4, 0.0) # NASA orange survey marker
	mat_orange.roughness = 0.4

	# Tripod leg 1
	for leg_i in range(3):
		var angle = leg_i * TAU / 3.0
		var leg = MeshInstance3D.new()
		var leg_mesh = CylinderMesh.new()
		leg_mesh.top_radius = 0.012
		leg_mesh.bottom_radius = 0.012
		leg_mesh.height = 0.48
		leg_mesh.material = mat_metal
		leg.mesh = leg_mesh
		leg.position = Vector3(cos(angle) * 0.14, 0.22, sin(angle) * 0.14)
		leg.rotation = Vector3(sin(angle) * 0.35, 0.0, -cos(angle) * 0.35)
		_gnomon_marker.add_child(leg)

	# Gimbaled center staff
	var staff = MeshInstance3D.new()
	var staff_mesh = CylinderMesh.new()
	staff_mesh.top_radius = 0.015
	staff_mesh.bottom_radius = 0.015
	staff_mesh.height = 0.55
	staff_mesh.material = mat_orange
	staff.mesh = staff_mesh
	staff.position.y = 0.28
	_gnomon_marker.add_child(staff)

	# Color calibration plate
	var plate = MeshInstance3D.new()
	var plate_mesh = BoxMesh.new()
	plate_mesh.size = Vector3(0.08, 0.12, 0.01)
	plate_mesh.material = mat_metal
	plate.mesh = plate_mesh
	plate.position = Vector3(0.06, 0.32, 0.0)
	_gnomon_marker.add_child(plate)

	add_child(_gnomon_marker)
	_gnomon_marker.visible = false

# Updates excavation depth and soil accumulation
func set_progress(p: float) -> void:
	_progress = clampf(p, 0.0, 1.0)

	# Excavation pit deepens progressively
	var current_depth = _progress * max_excavation_depth
	if _pit_mesh:
		_pit_mesh.position.y = -current_depth - 0.04
		_pit_mesh.visible = _progress > 0.02
	
	# Stratigraphic walls are revealed as depth increases
	for i in range(_strat_layers.size()):
		var layer = _strat_layers[i]
		if layer:
			var threshold = float(i) / float(_strat_layers.size()) * 0.8
			layer.visible = _progress > threshold
			# Scale slightly to simulate clean trench excavation
			var s = clampf((_progress - threshold) / 0.25, 0.1, 1.0)
			layer.scale.x = s
			layer.scale.z = s

	# Spoil pile grows outside the pit as soil is removed
	if _spoil_pile:
		_spoil_pile.visible = _progress > 0.05
		var pile_scale = clampf(_progress * 1.15, 0.0, 1.0)
		_spoil_pile.scale = Vector3(pile_scale * 1.1, pile_scale * 0.85, pile_scale * 1.05)

func set_marker_visible(is_vis: bool) -> void:
	if _gnomon_marker:
		_gnomon_marker.visible = is_vis

func get_marker_position() -> Vector3:
	if _gnomon_marker:
		return _gnomon_marker.global_position
	return global_position
