extends Node3D

# Echoes Beyond Earth - Natural Lunar Regolith Glittering Glint Effect
# Replaces artificial yellow circles and floating indicators with realistic,
# subtle specular glints from partially buried metallic or crystalline clasts.
# Characteristics:
# - Delicate, small points of light (1.5-3.0 cm micro-facets)
# - Natural silver-white / pale golden shimmer
# - Organic, irregular distribution on the regolith (no circles or geometric rings)
# - Subtle independent twinkling modulated by viewer distance & sun angle
# - Attached to the discovery's world-space position
# - Fades out progressively as excavation removes the upper soil layer

@export var is_metallic: bool = true
@export var patch_radius: float = 1.2
@export var glint_count: int = 14

var _glints: Array[MeshInstance3D] = []
var _glint_phases: Array[float] = []
var _glint_speeds: Array[float] = []
var _base_alphas: Array[float] = []
var _mats: Array[StandardMaterial3D] = []

var _excavation_progress: float = 0.0
var _player_ref: Node3D = null

func _ready() -> void:
	name = "LunarGlintEffect"
	_create_organic_glint_field()

func _create_organic_glint_field() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(global_position) + 42

	# Color palette: Delicate pale silver-white with hints of warm solar reflection
	var base_col = Color(0.92, 0.94, 0.98) if is_metallic else Color(0.96, 0.88, 0.65)
	
	# Quad mesh for tiny sparkling micro-facets (2.5 cm)
	var quad = QuadMesh.new()
	quad.size = Vector2(0.035, 0.035)

	for i in range(glint_count):
		# Irregular, non-circular organic distribution (clustered around micro-depressions)
		var r = sqrt(rng.randf_range(0.04, 1.0)) * patch_radius
		var theta = rng.randf_range(0.0, TAU)
		# Add irregular offset clusters
		var ox = cos(theta) * r + rng.randf_range(-0.15, 0.15)
		var oz = sin(theta) * r + rng.randf_range(-0.15, 0.15)
		var oy = rng.randf_range(0.01, 0.03) # Resting just atop regolith

		var mi = MeshInstance3D.new()
		mi.name = "GlintFacet_%d" % i
		mi.mesh = quad

		var mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		mat.albedo_color = Color(base_col.r, base_col.g, base_col.b, 0.65)
		mat.emission_enabled = true
		mat.emission = base_col
		mat.emission_energy_multiplier = rng.randf_range(0.6, 1.4)
		
		mi.material_override = mat
		mi.position = Vector3(ox, oy, oz)

		add_child(mi)
		_glints.append(mi)
		_mats.append(mat)
		_glint_phases.append(rng.randf_range(0.0, TAU))
		_glint_speeds.append(rng.randf_range(2.0, 5.5))
		_base_alphas.append(rng.randf_range(0.4, 0.85))

func _process(delta: float) -> void:
	if _excavation_progress >= 0.95:
		visible = false
		return
	
	if not _player_ref or not is_instance_valid(_player_ref):
		_player_ref = get_tree().get_first_node_in_group("player") as Node3D
		if not _player_ref:
			return

	var dist = global_position.distance_to(_player_ref.global_position)
	# Distance modulation: subtle from distance (12-30m), slightly more noticeable within 3-10m
	var dist_factor = clampf(remap(dist, 32.0, 6.0, 0.25, 1.0), 0.1, 1.0)
	# Fade out with excavation progress
	var exc_fade = clampf(1.0 - (_excavation_progress * 1.3), 0.0, 1.0)
	var final_master_alpha = dist_factor * exc_fade

	var t = Time.get_ticks_msec() * 0.001
	for i in range(_glints.size()):
		var phase = _glint_phases[i]
		var spd = _glint_speeds[i]
		# Independent twinkle simulation (sharp solar glints on rotating viewpoint)
		var twinkle = pow((sin(t * spd + phase) + 1.0) * 0.5, 3.0)
		var a = _base_alphas[i] * twinkle * final_master_alpha
		
		var mat = _mats[i]
		if mat:
			mat.albedo_color.a = a
			mat.emission_energy_multiplier = 0.5 + twinkle * 2.2 * final_master_alpha

func set_excavation_progress(p: float) -> void:
	_excavation_progress = clampf(p, 0.0, 1.0)
	if _excavation_progress >= 0.85:
		visible = false
	else:
		visible = true
