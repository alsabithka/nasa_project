extends Node3D

# Echoes Beyond Earth - Moon Terrain Builder
# Procedurally constructs the full lunar landscape in _ready()
# Uses only StandardMaterial3D - no shaders, no external assets.

func _ready() -> void:
	_build_ground()
	_build_craters()
	_build_rocks()
	_build_footprints()

# ---------------------------------------------------------------------------
# GROUND
# ---------------------------------------------------------------------------
func _build_ground() -> void:
	var ground_body = StaticBody3D.new()
	ground_body.name = "GroundBody"
	ground_body.collision_layer = 1
	ground_body.collision_mask = 2
	add_child(ground_body)

	var ground_mesh = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(140, 140)
	plane.subdivide_width = 0
	plane.subdivide_depth = 0
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.44, 0.46)
	mat.roughness = 0.92
	plane.material = mat
	ground_mesh.mesh = plane
	ground_body.add_child(ground_mesh)

	var col = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(140, 0.5, 140)
	col.shape = box
	col.position = Vector3(0, -0.25, 0)
	ground_body.add_child(col)

# ---------------------------------------------------------------------------
# CRATERS
# ---------------------------------------------------------------------------
func _build_craters() -> void:
	var positions = [
		Vector3(22, 0.0, 12),
		Vector3(-15, 0.0, -18),
		Vector3(-22, 0.0, 15),
		Vector3(38, 0.0, -8),
		Vector3(-35, 0.0, 25),
		Vector3(10, 0.0, -38)
	]
	var outer_radii = [5.0, 3.0, 7.0, 2.0, 4.0, 6.0]
	var heights    = [0.8, 0.5, 1.2, 0.3, 0.7, 1.0]

	var rim_mat = StandardMaterial3D.new()
	rim_mat.albedo_color = Color(0.36, 0.38, 0.4)
	rim_mat.roughness = 0.95

	var floor_mat = StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.26, 0.28, 0.3)
	floor_mat.roughness = 0.98

	for i in range(positions.size()):
		var outer_r = outer_radii[i]
		var inner_r = outer_r * 0.55
		var h       = heights[i]
		var pos     = positions[i]

		var container = Node3D.new()
		container.name = "Crater%d" % (i + 1)
		container.position = pos
		add_child(container)

		# Rim ring (CylinderMesh with top narrower than bottom to look like rim)
		var rim_mi = MeshInstance3D.new()
		var rim_mesh = CylinderMesh.new()
		rim_mesh.top_radius    = inner_r
		rim_mesh.bottom_radius = outer_r
		rim_mesh.height        = h
		rim_mesh.radial_segments = 20
		rim_mesh.cap_top    = false
		rim_mesh.cap_bottom = false
		rim_mesh.material = rim_mat
		rim_mi.mesh = rim_mesh
		rim_mi.position = Vector3(0, h * 0.5, 0)
		container.add_child(rim_mi)

		# Dark crater floor
		var floor_mi = MeshInstance3D.new()
		var floor_mesh = CylinderMesh.new()
		floor_mesh.top_radius    = inner_r * 0.98
		floor_mesh.bottom_radius = inner_r * 0.98
		floor_mesh.height        = 0.05
		floor_mesh.radial_segments = 20
		floor_mesh.material = floor_mat
		floor_mi.mesh = floor_mesh
		floor_mi.position = Vector3(0, -0.1, 0)
		container.add_child(floor_mi)

# ---------------------------------------------------------------------------
# ROCKS
# ---------------------------------------------------------------------------
func _build_rocks() -> void:
	var positions: Array = [
		Vector3(-28, 0.5, -8),
		Vector3(35, 0.5, 8),
		Vector3(-12, 0.8, 22),
		Vector3(20, 0.5, -30),
		Vector3(-38, 0.5, 12),
		Vector3(8, 0.4, 15),
		Vector3(-15, 0.5, -12),
		Vector3(25, 0.5, 5),
		Vector3(-5, 0.6, 30),
		Vector3(38, 0.5, -25),
		Vector3(-22, 0.5, 18),
		Vector3(12, 0.5, -8),
		Vector3(-32, 0.5, -22),
		Vector3(18, 0.6, 28),
		Vector3(-8, 0.5, -35)
	]
	var scales: Array = [2.8, 1.4, 2.0, 3.5, 1.8, 0.8, 1.2, 2.4, 0.6, 1.6, 1.0, 0.5, 2.2, 1.4, 0.9]

	var rock_mat = StandardMaterial3D.new()
	rock_mat.albedo_color = Color(0.34, 0.36, 0.38)
	rock_mat.roughness = 0.95

	for i in range(positions.size()):
		var s   = scales[i]
		var pos = positions[i]

		var body = StaticBody3D.new()
		body.name = "Rock%d" % (i + 1)
		body.position = pos
		body.scale = Vector3(s, s * 0.65, s)
		add_child(body)

		var mi = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 1.0
		sphere.height = 2.0
		sphere.radial_segments = 6
		sphere.rings = 4
		sphere.material = rock_mat
		mi.mesh = sphere
		body.add_child(mi)

		# Collision only for rocks large enough to block the player
		if s > 1.0:
			var col = CollisionShape3D.new()
			var shape = SphereShape3D.new()
			shape.radius = 1.0
			col.shape = shape
			body.add_child(col)

# ---------------------------------------------------------------------------
# FOOTPRINTS
# ---------------------------------------------------------------------------
func _build_footprints() -> void:
	var foot_mat = StandardMaterial3D.new()
	foot_mat.albedo_color = Color(0.34, 0.36, 0.38, 1.0)
	foot_mat.roughness = 0.98

	# 10 footprints stepping from (1,0,1) toward (16,0,11)
	var num_prints = 10
	var start = Vector2(1.0, 1.0)
	var end_p = Vector2(16.0, 11.0)

	for i in range(num_prints):
		var t  = float(i) / float(num_prints - 1)
		var bx = lerp(start.x, end_p.x, t)
		var bz = lerp(start.y, end_p.y, t)

		# Alternate left/right offset for natural stride
		var side_offset = 0.18 if (i % 2 == 0) else -0.18

		var fp = MeshInstance3D.new()
		fp.name = "Footprint%d" % (i + 1)
		var plane = PlaneMesh.new()
		plane.size = Vector2(0.25, 0.4)
		plane.material = foot_mat
		fp.mesh = plane
		fp.position = Vector3(bx + side_offset, 0.005, bz)
		add_child(fp)
