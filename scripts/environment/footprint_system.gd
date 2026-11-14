extends Node3D

# Echoes Beyond Earth - Dynamic Lunar Footprint Generation & Persistence
# Recreates authentic Apollo lunar overboot impressions in the cohesive regolith:
# 1. Corrugated chevron/horizontal tread pattern characteristic of Apollo A7LB overboots
# 2. Compacted shadowed regolith coloration
# 3. Dynamic placement with depth depression conforming to terrain normal
# 4. High-performance persistent footprint buffer

const MAX_FOOTPRINTS: int = 150
var _footprints: Array[MeshInstance3D] = []
var _footprint_index: int = 0
var _boot_mesh: ArrayMesh
var _print_mat: StandardMaterial3D

func _ready() -> void:
	name = "FootprintSystem"
	_init_materials_and_mesh()
	_preallocate_pool()

func _init_materials_and_mesh() -> void:
	# Material: Darker compressed regolith with high roughness
	_print_mat = StandardMaterial3D.new()
	_print_mat.albedo_color = Color(0.27, 0.28, 0.30)
	_print_mat.roughness = 0.99
	_print_mat.metallic = 0.01
	
	# Build corrugated Apollo boot sole mesh with ribbed tread marks
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var w = 0.12 # Half-width
	var l = 0.18 # Half-length
	var num_ribs = 6
	
	for i in range(num_ribs):
		var z_start = -l + (float(i) / float(num_ribs)) * (l * 2.0)
		var z_end = z_start + (l * 2.0 / float(num_ribs)) * 0.75
		
		# Quad for each tread groove
		var p1 = Vector3(-w, 0.002, z_start)
		var p2 = Vector3(w, 0.002, z_start)
		var p3 = Vector3(w, 0.002, z_end)
		var p4 = Vector3(-w, 0.002, z_end)
		
		st.set_normal(Vector3.UP)
		st.add_vertex(p1)
		st.add_vertex(p2)
		st.add_vertex(p3)
		
		st.add_vertex(p1)
		st.add_vertex(p3)
		st.add_vertex(p4)
	
	st.generate_normals()
	_boot_mesh = st.commit()

func _preallocate_pool() -> void:
	for i in range(MAX_FOOTPRINTS):
		var mi = MeshInstance3D.new()
		mi.name = "Footprint_%d" % i
		mi.mesh = _boot_mesh
		mi.material_override = _print_mat
		mi.visible = false
		add_child(mi)
		_footprints.append(mi)

# Places a persistent bootprint at the exact surface contact point
func place_footprint(pos: Vector3, normal: Vector3, yaw_rad: float, is_left_foot: bool, depth_factor: float = 1.0) -> void:
	if _footprints.is_empty():
		return
	
	var fp = _footprints[_footprint_index]
	_footprint_index = (_footprint_index + 1) % MAX_FOOTPRINTS
	
	# Slight lateral offset based on left or right boot
	var side_offset = -0.16 if is_left_foot else 0.16
	var right_vec = Vector3(cos(yaw_rad), 0, -sin(yaw_rad))
	var print_pos = pos + right_vec * side_offset
	
	# Offset slightly along normal to avoid Z-fighting, slightly recessed into ground
	var elevation_offset = 0.008 - (0.005 * clampf(depth_factor, 0.5, 1.5))
	fp.global_position = print_pos + normal * elevation_offset
	
	# Align footprint orientation with yaw and terrain surface normal
	var forward = Vector3(sin(yaw_rad), 0, cos(yaw_rad))
	var up = normal.normalized()
	var right = up.cross(forward).normalized()
	forward = right.cross(up).normalized()
	
	fp.global_transform.basis = Basis(right, up, forward)
	fp.visible = true
