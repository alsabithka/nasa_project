extends Node3D

# Echoes Beyond Earth - NASA Apollo Scientific Lunar Excavation Tools
# - Lunar Regolith Scoop: Teflon-coated aluminum pan with tubular shaft
# - Geological Soft-Bristle Dust Brush: For gentle cleaning of rock clasts and hardware
# - Apollo Sample Return Container / Teflon Sample Bag: For contamination-free storage

enum ActiveTool { NONE, SCOOP, BRUSH, SAMPLE_BAG }

var current_tool: ActiveTool = ActiveTool.NONE

var scoop_node: Node3D
var brush_node: Node3D
var bag_node: Node3D

func _ready() -> void:
	name = "LunarExcavationTools"
	_build_tools()
	set_tool(ActiveTool.NONE)

func _build_tools() -> void:
	var mat_metal = StandardMaterial3D.new()
	mat_metal.albedo_color = Color(0.85, 0.86, 0.88)
	mat_metal.metallic = 0.9
	mat_metal.roughness = 0.25

	var mat_gold = StandardMaterial3D.new()
	mat_gold.albedo_color = Color(0.95, 0.78, 0.25)
	mat_gold.metallic = 0.8
	mat_gold.roughness = 0.3

	var mat_brush = StandardMaterial3D.new()
	mat_brush.albedo_color = Color(0.72, 0.70, 0.65)
	mat_brush.roughness = 0.95

	var mat_teflon = StandardMaterial3D.new()
	mat_teflon.albedo_color = Color(0.92, 0.93, 0.95)
	mat_teflon.roughness = 0.6

	# --- 1. Lunar Regolith Scoop (Apollo 16/17 design) ---
	scoop_node = Node3D.new()
	scoop_node.name = "LunarScoop"
	
	# Scoop handle shaft (60 cm)
	var handle = MeshInstance3D.new()
	var h_mesh = CylinderMesh.new()
	h_mesh.top_radius = 0.014
	h_mesh.bottom_radius = 0.014
	h_mesh.height = 0.60
	h_mesh.material = mat_metal
	handle.mesh = h_mesh
	handle.rotation.x = deg_to_rad(35.0)
	scoop_node.add_child(handle)

	# Scoop pan (tilted curved blade)
	var pan = MeshInstance3D.new()
	var pan_mesh = BoxMesh.new()
	pan_mesh.size = Vector3(0.18, 0.06, 0.22)
	pan_mesh.material = mat_metal
	pan.mesh = pan_mesh
	pan.position = Vector3(0.0, -0.26, 0.22)
	pan.rotation.x = deg_to_rad(-15.0)
	scoop_node.add_child(pan)
	add_child(scoop_node)

	# --- 2. Geological Dust Brush ---
	brush_node = Node3D.new()
	brush_node.name = "GeologicalBrush"
	
	var brush_handle = MeshInstance3D.new()
	var bh_mesh = CylinderMesh.new()
	bh_mesh.top_radius = 0.012
	bh_mesh.bottom_radius = 0.010
	bh_mesh.height = 0.30
	bh_mesh.material = mat_metal
	brush_handle.mesh = bh_mesh
	brush_node.add_child(brush_handle)

	var bristle = MeshInstance3D.new()
	var b_mesh = CylinderMesh.new()
	b_mesh.top_radius = 0.035
	b_mesh.bottom_radius = 0.025
	b_mesh.height = 0.10
	b_mesh.material = mat_brush
	bristle.mesh = b_mesh
	bristle.position.y = -0.18
	brush_node.add_child(bristle)
	add_child(brush_node)

	# --- 3. Apollo Sample Return Container / Teflon Bag ---
	bag_node = Node3D.new()
	bag_node.name = "SampleContainer"
	
	var bag = MeshInstance3D.new()
	var bag_mesh = BoxMesh.new()
	bag_mesh.size = Vector3(0.16, 0.20, 0.10)
	bag_mesh.material = mat_teflon
	bag.mesh = bag_mesh
	bag_node.add_child(bag)

	var seal_strip = MeshInstance3D.new()
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(0.18, 0.03, 0.04)
	s_mesh.material = mat_gold
	seal_strip.mesh = s_mesh
	seal_strip.position.y = 0.11
	bag_node.add_child(seal_strip)
	add_child(bag_node)

func set_tool(tool: ActiveTool) -> void:
	current_tool = tool
	if scoop_node:
		scoop_node.visible = (tool == ActiveTool.SCOOP)
	if brush_node:
		brush_node.visible = (tool == ActiveTool.BRUSH)
	if bag_node:
		bag_node.visible = (tool == ActiveTool.SAMPLE_BAG)
