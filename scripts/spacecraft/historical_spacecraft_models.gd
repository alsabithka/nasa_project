extends RefCounted
class_name HistoricalSpacecraftModels

# Echoes Beyond Earth - Historically Accurate NASA Spacecraft 3D Procedural Mesh Factory
# Generates authentic 3D mechanical models with exact physical dimensions, PBR materials,
# component inspection hierarchies, and documented mission conditions.

# --- PBR Material Palette ---
static func get_material(mat_type: String, dust_level: float = 0.0) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	match mat_type:
		"aluminum_anodized":
			mat.albedo_color = Color(0.82, 0.82, 0.84).lerp(Color(0.68, 0.44, 0.32), dust_level * 0.4)
			mat.metallic = 0.85
			mat.roughness = lerp(0.35, 0.85, dust_level)
		"titanium":
			mat.albedo_color = Color(0.55, 0.55, 0.58).lerp(Color(0.62, 0.40, 0.28), dust_level * 0.4)
			mat.metallic = 0.90
			mat.roughness = lerp(0.40, 0.88, dust_level)
		"stainless_steel":
			mat.albedo_color = Color(0.72, 0.72, 0.75).lerp(Color(0.65, 0.42, 0.30), dust_level * 0.4)
			mat.metallic = 0.92
			mat.roughness = lerp(0.28, 0.82, dust_level)
		"gold_kapton_mli":
			mat.albedo_color = Color(0.95, 0.76, 0.22).lerp(Color(0.68, 0.45, 0.30), dust_level * 0.5)
			mat.metallic = 0.88
			mat.roughness = lerp(0.22, 0.80, dust_level)
		"silver_kapton_mli":
			mat.albedo_color = Color(0.92, 0.92, 0.94).lerp(Color(0.65, 0.42, 0.30), dust_level * 0.5)
			mat.metallic = 0.90
			mat.roughness = lerp(0.20, 0.78, dust_level)
		"solar_cell_silicon":
			# Dark blue/black photovoltaic cell with anti-reflective coating
			mat.albedo_color = Color(0.06, 0.09, 0.22).lerp(Color(0.62, 0.40, 0.28), dust_level * 0.75)
			mat.metallic = 0.40
			mat.roughness = lerp(0.18, 0.92, dust_level)
		"solar_cell_gaas":
			# Deep violet/charcoal Gallium Arsenide cell
			mat.albedo_color = Color(0.08, 0.06, 0.14).lerp(Color(0.62, 0.40, 0.28), dust_level * 0.75)
			mat.metallic = 0.50
			mat.roughness = lerp(0.20, 0.90, dust_level)
		"carbon_fiber":
			mat.albedo_color = Color(0.15, 0.15, 0.16).lerp(Color(0.55, 0.38, 0.28), dust_level * 0.35)
			mat.metallic = 0.20
			mat.roughness = lerp(0.50, 0.85, dust_level)
		"optical_glass":
			mat.albedo_color = Color(0.12, 0.18, 0.24)
			mat.metallic = 0.10
			mat.roughness = 0.10
		"rtg_casing":
			mat.albedo_color = Color(0.38, 0.38, 0.40).lerp(Color(0.60, 0.40, 0.30), dust_level * 0.4)
			mat.metallic = 0.75
			mat.roughness = 0.65
		"white_ceramic_paint":
			mat.albedo_color = Color(0.88, 0.88, 0.86).lerp(Color(0.65, 0.42, 0.30), dust_level * 0.65)
			mat.metallic = 0.05
			mat.roughness = lerp(0.45, 0.92, dust_level)
		"permafrost_frost":
			mat.albedo_color = Color(0.92, 0.95, 0.98)
			mat.metallic = 0.02
			mat.roughness = 0.85
		_:
			mat.albedo_color = Color(0.6, 0.6, 0.6)
	return mat

static func _attach_component_info(node: Node, comp_name: String, desc: String, spec: String) -> void:
	node.set_meta("component_name", comp_name)
	node.set_meta("component_desc", desc)
	node.set_meta("component_spec", spec)

# ==============================================================================
# PART 1: MARS SURFACE MACHINERY
# ==============================================================================

# 1. Sojourner Rover (Ares Vallis: 19.33° N, 326.45° E)
# Dimensions: 0.65m L x 0.48m W x 0.30m H, Mass: 11.5 kg
static func build_sojourner_rover(dust_level: float = 0.45) -> Node3D:
	var root = Node3D.new()
	root.name = "SojournerRover"
	_attach_component_info(root, "Sojourner Rover", "NASA's first Mars microrover (Mars Pathfinder, 1997).", "Dimensions: 65x48x30 cm | Mass: 11.5 kg")

	var mat_alu = get_material("aluminum_anodized", dust_level)
	var mat_gold = get_material("gold_kapton_mli", dust_level)
	var mat_solar = get_material("solar_cell_gaas", dust_level)
	var mat_wheel = get_material("stainless_steel", dust_level)
	var mat_lens = get_material("optical_glass", 0.0)

	# Warm Electronics Box (WEB) Chassis
	var chassis = MeshInstance3D.new()
	chassis.name = "Chassis_WEB"
	var c_box = BoxMesh.new()
	c_box.size = Vector3(0.52, 0.16, 0.36)
	c_box.material = mat_gold
	chassis.mesh = c_box
	chassis.position = Vector3(0.0, 0.20, 0.0)
	_attach_component_info(chassis, "Warm Electronics Box (WEB)", "Insulated internal chassis containing 80C85 CPU, modem, and lithium batteries, protected by silica aerogel.", "Operating temp: -40°C to +40°C | Aerogel insulation: 2.5 cm")
	root.add_child(chassis)

	# GaAs Solar Array Deck
	var solar_deck = MeshInstance3D.new()
	solar_deck.name = "SolarArrayDeck"
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.60, 0.02, 0.42)
	s_box.material = mat_solar
	solar_deck.mesh = s_box
	solar_deck.position = Vector3(0.0, 0.29, 0.0)
	_attach_component_info(solar_deck, "GaAs Solar Array", "0.22 m² Gallium Arsenide solar array generating peak 16W electrical power under Martian sunlight.", "Area: 0.22 m² | Peak output: 16 W | Cells: GaAs/Ge")
	root.add_child(solar_deck)

	# 6-Wheel Rocker-Bogie Suspension & Wheels
	var suspension = Node3D.new()
	suspension.name = "RockerBogieSuspension"
	_attach_component_info(suspension, "Rocker-Bogie Suspension", "Articulated mechanical suspension distributing weight equally over 6 wheels without springs.", "Max obstacle height: 13 cm | Pitch articulation: ±45°")
	root.add_child(suspension)

	var wheel_x = [-0.25, 0.0, 0.25]
	var wheel_z = [-0.24, 0.24]
	for wx in wheel_x:
		for wz in wheel_z:
			var wheel = MeshInstance3D.new()
			wheel.name = "Wheel_%s_%s" % ["L" if wz < 0 else "R", "Front" if wx > 0 else ("Mid" if wx == 0 else "Rear")]
			var w_cyl = CylinderMesh.new()
			w_cyl.top_radius = 0.065
			w_cyl.bottom_radius = 0.065
			w_cyl.height = 0.070
			w_cyl.radial_segments = 12
			w_cyl.material = mat_wheel
			wheel.mesh = w_cyl
			wheel.rotation_degrees = Vector3(90, 0, 0)
			wheel.position = Vector3(wx, 0.065, wz)
			_attach_component_info(wheel, "Stainless Steel Cleated Wheel", "Independently driven 13cm wheel with stainless steel grousers for loose regolith traction.", "Diameter: 13 cm | Width: 7 cm | Cleats: 20 grousers")
			suspension.add_child(wheel)

			# Suspension rocker arm strut
			var strut = MeshInstance3D.new()
			var s_cyl = CylinderMesh.new()
			s_cyl.top_radius = 0.012
			s_cyl.bottom_radius = 0.012
			s_cyl.height = 0.16
			s_cyl.material = mat_alu
			strut.mesh = s_cyl
			strut.position = Vector3(wx, 0.14, wz * 0.75)
			strut.rotation_degrees = Vector3(0, 0, 25 if wx < 0 else -25)
			suspension.add_child(strut)

	# Alpha Proton X-ray Spectrometer (APXS) on rear deployment mechanism
	var apxs = MeshInstance3D.new()
	apxs.name = "APXS_Sensor"
	var a_cyl = CylinderMesh.new()
	a_cyl.top_radius = 0.045
	a_cyl.bottom_radius = 0.045
	a_cyl.height = 0.080
	a_cyl.material = mat_alu
	apxs.mesh = a_cyl
	apxs.position = Vector3(-0.32, 0.12, 0.0)
	apxs.rotation_degrees = Vector3(0, 0, 90)
	_attach_component_info(apxs, "Alpha Proton X-ray Spectrometer (APXS)", "Deploys Curium-244 radioactive source to analyze alpha backscatter and X-ray fluorescence of rocks.", "Radioactive source: Cm-244 | Sensor: Alpha/Proton/X-ray")
	root.add_child(apxs)

	# Forward Stereo Cameras and UHF Antenna
	var fwd_cam = MeshInstance3D.new()
	fwd_cam.name = "ForwardStereoCameras"
	var cam_box = BoxMesh.new()
	cam_box.size = Vector3(0.04, 0.05, 0.14)
	cam_box.material = mat_alu
	fwd_cam.mesh = cam_box
	fwd_cam.position = Vector3(0.28, 0.27, 0.0)
	_attach_component_info(fwd_cam, "Stereo Forward Cameras", "Dual monochrome CCD cameras (768x484) providing forward 3D stereo vision and obstacle hazard mapping.", "Resolution: 768x484 px | Baseline: 12 cm")
	root.add_child(fwd_cam)

	var uhf_antenna = MeshInstance3D.new()
	uhf_antenna.name = "UHF_WhipAntenna"
	var u_cyl = CylinderMesh.new()
	u_cyl.top_radius = 0.004
	u_cyl.bottom_radius = 0.004
	u_cyl.height = 0.28
	u_cyl.material = mat_alu
	uhf_antenna.mesh = u_cyl
	uhf_antenna.position = Vector3(-0.20, 0.44, 0.16)
	_attach_component_info(uhf_antenna, "UHF Whip Antenna", "Communicates telemetry and science data with the Pathfinder lander base station at 459.7 MHz.", "Frequency: 459.7 MHz | Range: up to 500 m")
	root.add_child(uhf_antenna)

	return root

# 2. Mars Pathfinder Lander (Carl Sagan Memorial Station)
# Deployed footprint: 2.75m diameter, 0.90m height
static func build_pathfinder_lander(dust_level: float = 0.50) -> Node3D:
	var root = Node3D.new()
	root.name = "PathfinderLander"
	_attach_component_info(root, "Mars Pathfinder Lander", "Stationary Carl Sagan Memorial Station; touched down July 4, 1997 in Ares Vallis.", "Landed mass: 264 kg | Deployed diameter: 2.75 m")

	var mat_alu = get_material("aluminum_anodized", dust_level)
	var mat_solar = get_material("solar_cell_silicon", dust_level)
	var mat_gold = get_material("gold_kapton_mli", dust_level)
	var mat_airbag = get_material("white_ceramic_paint", dust_level * 0.9)
	var mat_lens = get_material("optical_glass", 0.0)

	# Central Triangular Platform
	var base_hub = MeshInstance3D.new()
	base_hub.name = "CentralBasePlatform"
	var b_prism = CylinderMesh.new()
	b_prism.radial_segments = 3
	b_prism.top_radius = 0.85
	b_prism.bottom_radius = 0.85
	b_prism.height = 0.22
	b_prism.material = mat_gold
	base_hub.mesh = b_prism
	base_hub.position = Vector3(0.0, 0.16, 0.0)
	_attach_component_info(base_hub, "Central Electronics Hub", "Base station housing high-capacity silver-zinc batteries, transmitter, and mission computer.", "Capacity: 40 Ah | Power: 1200 Wh/sol")
	root.add_child(base_hub)

	# 3 Folded-Out Triangular Solar Petals
	for i in range(3):
		var angle = float(i) * 120.0 * (PI / 180.0)
		var petal_dir = Vector3(cos(angle), 0.0, sin(angle))
		var petal = MeshInstance3D.new()
		petal.name = "SolarPetal_%d" % (i + 1)
		var p_mesh = BoxMesh.new()
		p_mesh.size = Vector3(1.10, 0.04, 0.85)
		p_mesh.material = mat_solar
		petal.mesh = p_mesh
		petal.position = petal_dir * 1.05 + Vector3(0.0, 0.08, 0.0)
		petal.rotation_degrees = Vector3(4, -rad_to_deg(angle), 0)
		_attach_component_info(petal, "Deployable Solar Petal %d" % (i + 1), "Structural composite panel covered with silicon solar cells that opened after airbag deflation.", "Total solar area: 5.6 m² | Output: 1,200 Wh/sol")
		root.add_child(petal)

	# Deflated Airbag Bunches (Vectran fabric remnants)
	for i in range(3):
		var angle = float(i * 120 + 60) * (PI / 180.0)
		var bag = MeshInstance3D.new()
		bag.name = "DeflatedAirbagBundle_%d" % (i + 1)
		var bag_mesh = SphereMesh.new()
		bag_mesh.radius = 0.35
		bag_mesh.height = 0.25
		bag_mesh.radial_segments = 8
		bag_mesh.material = mat_airbag
		bag.mesh = bag_mesh
		bag.scale = Vector3(1.6, 0.6, 1.2)
		bag.position = Vector3(cos(angle) * 1.35, 0.10, sin(angle) * 1.35)
		_attach_component_info(bag, "Deflated Airbag Remnant", "Multi-layered woven Vectran fabric airbags that cushioned the 14 m/s planetary impact.", "Material: Vectran (4x strength of Kevlar) | 24 lobes total")
		root.add_child(bag)

	# Sojourner Roll-out Deployer Ramps (Kevlar tracks)
	var ramp = MeshInstance3D.new()
	ramp.name = "RoverDeploymentRamp"
	var r_box = BoxMesh.new()
	r_box.size = Vector3(0.85, 0.02, 0.38)
	r_box.material = mat_alu
	ramp.mesh = r_box
	ramp.position = Vector3(1.15, 0.06, 0.0)
	ramp.rotation_degrees = Vector3(0, 0, -14)
	_attach_component_info(ramp, "Rover Deployment Ramp", "Dual woven Kevlar deployment ramps on which Sojourner drove down onto the Martian surface.", "Width: 38 cm | Angle: 14° descent")
	root.add_child(ramp)

	# IMP (Imager for Mars Pathfinder) Mast
	var imp_mast = MeshInstance3D.new()
	imp_mast.name = "IMP_CameraMast"
	var m_cyl = CylinderMesh.new()
	m_cyl.top_radius = 0.03
	m_cyl.bottom_radius = 0.03
	m_cyl.height = 0.85
	m_cyl.material = mat_alu
	imp_mast.mesh = m_cyl
	imp_mast.position = Vector3(0.0, 0.65, 0.0)
	_attach_component_info(imp_mast, "Imager for Mars Pathfinder (IMP)", "Stereoscopic multispectral camera mounted on an 85 cm deployable mast for 360° panoramas.", "Detector: Dual 256x256 CCD | Filters: 12 geological filters")
	root.add_child(imp_mast)

	var imp_head = MeshInstance3D.new()
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.18, 0.12, 0.22)
	h_box.material = mat_gold
	imp_head.mesh = h_box
	imp_head.position = Vector3(0.0, 1.08, 0.0)
	root.add_child(imp_head)

	# ASI/MET Weather Mast
	var met_mast = MeshInstance3D.new()
	met_mast.name = "ASI_MET_Station"
	var met_cyl = CylinderMesh.new()
	met_cyl.top_radius = 0.015
	met_cyl.bottom_radius = 0.015
	met_cyl.height = 1.15
	met_cyl.material = mat_alu
	met_mast.mesh = met_cyl
	met_mast.position = Vector3(-0.35, 0.75, 0.25)
	_attach_component_info(met_mast, "ASI/MET Meteorology Mast", "Atmospheric Structure Instrument and Meteorology package measuring pressure, temperature, and wind.", "Sensors: 3 platinum thermocouples, Tavis pressure sensor")
	root.add_child(met_mast)

	# High-Gain Antenna (HGA) Parabolic Dish
	var hga_dish = MeshInstance3D.new()
	hga_dish.name = "HighGainAntennaDish"
	var dish_mesh = CylinderMesh.new()
	dish_mesh.top_radius = 0.32
	dish_mesh.bottom_radius = 0.05
	dish_mesh.height = 0.08
	dish_mesh.material = mat_alu
	hga_dish.mesh = dish_mesh
	hga_dish.position = Vector3(0.28, 0.42, -0.22)
	hga_dish.rotation_degrees = Vector3(35, 45, 0)
	_attach_component_info(hga_dish, "High-Gain X-Band Dish", "Steerable parabolic antenna transmitting scientific imagery directly to Deep Space Network at 8.4 GHz.", "Diameter: 64 cm | Frequency: 8.4 GHz (X-band)")
	root.add_child(hga_dish)

	return root

# 3. Mars Exploration Rovers: Spirit & Opportunity
# Dimensions: 1.6m L x 2.3m W x 1.5m H, Mass: 185 kg
static func build_mer_rover(rover_id: String = "opportunity", dust_level: float = 0.60) -> Node3D:
	var root = Node3D.new()
	var is_spirit = (rover_id.to_lower() == "spirit")
	root.name = "SpiritRover" if is_spirit else "OpportunityRover"
	var rover_title = "MER Spirit (MER-A)" if is_spirit else "MER Opportunity (MER-B)"
	var landing_loc = "Gusev Crater (Columbia Hills / Troy)" if is_spirit else "Meridiani Planum (Perseverance Valley)"
	_attach_component_info(root, rover_title, "NASA Mars Exploration Rover stationed at %s." % landing_loc, "Dimensions: 1.6x2.3x1.5 m | Mass: 185 kg | Odo: %s km" % ("7.73" if is_spirit else "45.16"))

	var mat_alu = get_material("aluminum_anodized", dust_level)
	var mat_gold = get_material("gold_kapton_mli", dust_level)
	var mat_solar = get_material("solar_cell_silicon", dust_level * 0.95)
	var mat_wheel = get_material("aluminum_anodized", dust_level)
	var mat_lens = get_material("optical_glass", 0.0)

	# Warm Electronics Box (WEB)
	var chassis = MeshInstance3D.new()
	chassis.name = "WarmElectronicsBox_WEB"
	var c_box = BoxMesh.new()
	c_box.size = Vector3(1.15, 0.32, 0.75)
	c_box.material = mat_gold
	chassis.mesh = c_box
	chassis.position = Vector3(0.0, 0.45, 0.0)
	_attach_component_info(chassis, "Warm Electronics Box (WEB)", "Aerogel-insulated chassis housing RAD6000 computer (20 MHz, 128 MB DRAM), Li-ion batteries, and RHUs.", "Insulation: Silica aerogel | CPU: 20 MHz BAE RAD6000")
	root.add_child(chassis)

	# Swept Solar Array Wings Deck (Span: 2.30 m)
	var solar_deck = MeshInstance3D.new()
	solar_deck.name = "SolarArrayDeck"
	var s_mesh = BoxMesh.new()
	s_mesh.size = Vector3(1.50, 0.03, 1.95)
	s_mesh.material = mat_solar
	solar_deck.mesh = s_mesh
	solar_deck.position = Vector3(0.0, 0.62, 0.0)
	_attach_component_info(solar_deck, "Triple-Junction Solar Array", "1.3 m² triple-junction solar panels generating up to 900 Wh/sol, heavily mantled by Martian atmospheric dust.", "Area: 1.3 m² | Output: 140 W (clean) to <50 W (dust-covered)")
	root.add_child(solar_deck)

	# Rocker-Bogie Suspension & 6 Machined Wheels
	var suspension = Node3D.new()
	suspension.name = "RockerBogieSuspension"
	_attach_component_info(suspension, "Rocker-Bogie Suspension", "Titanium differential suspension with 6 in-wheel motors and spiral-cleated aluminum wheels.", "Ground clearance: 30 cm | Max tilt: 45°")
	root.add_child(suspension)

	var wheel_coords = [
		{"pos": Vector3(0.55, 0.13, -0.65), "name": "Front_Left", "steer": true},
		{"pos": Vector3(0.55, 0.13, 0.65), "name": "Front_Right", "steer": true},
		{"pos": Vector3(0.0, 0.13, -0.72), "name": "Mid_Left", "steer": false},
		{"pos": Vector3(0.0, 0.13, 0.72), "name": "Mid_Right", "steer": false},
		{"pos": Vector3(-0.55, 0.13, -0.65), "name": "Rear_Left", "steer": true},
		{"pos": Vector3(-0.55, 0.13, 0.65), "name": "Rear_Right", "steer": true}
	]

	for wc in wheel_coords:
		var wheel = MeshInstance3D.new()
		wheel.name = "Wheel_" + wc["name"]
		var w_cyl = CylinderMesh.new()
		w_cyl.top_radius = 0.13
		w_cyl.bottom_radius = 0.13
		w_cyl.height = 0.16
		w_cyl.radial_segments = 14
		w_cyl.material = mat_wheel
		wheel.mesh = w_cyl
		wheel.rotation_degrees = Vector3(90, 0, 0)
		wheel.position = wc["pos"]
		# Spirit's right-front wheel seized on Sol 779 and was dragged thereafter
		if is_spirit and wc["name"] == "Front_Right":
			wheel.rotation_degrees = Vector3(90, 22, 0)
			_attach_component_info(wheel, "Seized Right-Front Drive Wheel", "Spirit's right-front wheel motor permanently failed on Sol 779 (March 2006); dragged through sand.", "Failure Sol: 779 | Resistance: Stalled/Jammed")
		else:
			_attach_component_info(wheel, "Machined Aluminum Wheel", "26cm aluminum wheel with spiral flexures and aggressive cleat grousers for loose soil.", "Diameter: 26 cm | Width: 16 cm")
		suspension.add_child(wheel)

	# Pancam Mast Assembly (PMA)
	var mast = MeshInstance3D.new()
	mast.name = "PancamMastAssembly"
	var m_cyl = CylinderMesh.new()
	m_cyl.top_radius = 0.035
	m_cyl.bottom_radius = 0.035
	m_cyl.height = 0.88
	m_cyl.material = mat_alu
	mast.mesh = m_cyl
	mast.position = Vector3(0.40, 1.08, 0.22)
	_attach_component_info(mast, "Pancam Mast Assembly (PMA)", "1.5m tall periscope mast carrying Panoramic Cameras (Pancam), Navcams, and Miniature Thermal Emission Spectrometer (Mini-TES).", "Height: 1.5 m above surface | Azimuth: 360° | Elevation: ±90°")
	root.add_child(mast)

	var mast_head = MeshInstance3D.new()
	mast_head.name = "CameraHeadBar"
	var h_box = BoxMesh.new()
	h_box.size = Vector3(0.16, 0.10, 0.38)
	h_box.material = mat_gold
	mast_head.mesh = h_box
	mast_head.position = Vector3(0.40, 1.54, 0.22)
	root.add_child(mast_head)

	# High-Gain Antenna (HGA)
	var hga = MeshInstance3D.new()
	hga.name = "HighGainAntennaDish"
	var d_cyl = CylinderMesh.new()
	d_cyl.top_radius = 0.14
	d_cyl.bottom_radius = 0.02
	d_cyl.height = 0.05
	d_cyl.material = mat_alu
	hga.mesh = d_cyl
	hga.position = Vector3(-0.35, 0.72, -0.25)
	hga.rotation_degrees = Vector3(25, -35, 0)
	_attach_component_info(hga, "High-Gain X-band Antenna", "Steerable 28cm parabolic dish communicating directly with Earth's Deep Space Network.", "Diameter: 28 cm | Rate: up to 28 kbps")
	root.add_child(hga)

	# Instrument Deployment Device (IDD / Robotic Arm)
	var arm = Node3D.new()
	arm.name = "InstrumentDeploymentArm_IDD"
	arm.position = Vector3(0.55, 0.42, 0.0)
	_attach_component_info(arm, "Instrument Deployment Device (IDD)", "5-degree-of-freedom robotic arm holding the 4-sensor scientific analysis turret.", "Reach: 0.85 m | Payload mass: 5.4 kg")
	root.add_child(arm)

	var arm_segment1 = MeshInstance3D.new()
	var as1 = CylinderMesh.new()
	as1.top_radius = 0.025
	as1.bottom_radius = 0.025
	as1.height = 0.38
	as1.material = mat_alu
	arm_segment1.mesh = as1
	arm_segment1.rotation_degrees = Vector3(0, 0, 45)
	arm_segment1.position = Vector3(0.12, -0.12, 0.0)
	arm.add_child(arm_segment1)

	var turret = MeshInstance3D.new()
	turret.name = "ScienceInstrumentTurret"
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 0.09
	t_cyl.bottom_radius = 0.09
	t_cyl.height = 0.12
	t_cyl.material = mat_alu
	turret.mesh = t_cyl
	turret.position = Vector3(0.26, -0.26, 0.0)
	_attach_component_info(turret, "Science Instrument Turret", "Houses Microscopic Imager (MI), Mössbauer Spectrometer, APXS, and Rock Abrasion Tool (RAT).", "Tools: MI, MB, APXS, RAT | Rotation: 360°")
	arm.add_child(turret)

	return root

# 4. Viking 1 & Viking 2 Landers
# Height: 2.1m, Leg span: 3.0m, Mass: 612 kg
static func build_viking_lander(viking_num: int = 1, dust_level: float = 0.55) -> Node3D:
	var root = Node3D.new()
	root.name = "Viking%dLander" % viking_num
	var site = "Chryse Planitia" if viking_num == 1 else "Utopia Planitia"
	_attach_component_info(root, "Viking %d Lander" % viking_num, "NASA's historic first operational Mars lander at %s (1976)." % site, "Landed mass: 612 kg | Diameter: 3.0 m | Power: Dual SNAP-19 RTGs")

	var mat_alu = get_material("aluminum_anodized", dust_level)
	var mat_rtg = get_material("rtg_casing", dust_level * 0.8)
	var mat_white = get_material("white_ceramic_paint", dust_level * 0.9)
	var mat_titanium = get_material("titanium", dust_level)

	# Hexagonal Monocoque Base
	var hex_body = MeshInstance3D.new()
	hex_body.name = "HexagonalMainPlatform"
	var h_cyl = CylinderMesh.new()
	h_cyl.radial_segments = 6
	h_cyl.top_radius = 0.92
	h_cyl.bottom_radius = 0.92
	h_cyl.height = 0.48
	h_cyl.material = mat_alu
	hex_body.mesh = h_cyl
	hex_body.position = Vector3(0.0, 0.72, 0.0)
	_attach_component_info(hex_body, "Hexagonal Titanium/Alloy Platform", "Heavy load-bearing platform housing GCMS biology laboratory, tape recorders, and guidance computers.", "Construction: Titanium/Al-alloy | Width: 1.5 m across flats")
	root.add_child(hex_body)

	# 3 Inverted Tripod Landing Legs with Circular Footpads (Span: 3.0m)
	for i in range(3):
		var angle = float(i) * 120.0 * (PI / 180.0)
		var leg_root = Node3D.new()
		leg_root.name = "LandingLeg_%d" % (i + 1)
		root.add_child(leg_root)

		var leg_dir = Vector3(cos(angle), 0.0, sin(angle))
		var foot_pos = leg_dir * 1.50 + Vector3(0.0, 0.05, 0.0)

		# Main landing strut
		var strut = MeshInstance3D.new()
		var s_cyl = CylinderMesh.new()
		s_cyl.top_radius = 0.035
		s_cyl.bottom_radius = 0.035
		s_cyl.height = 1.15
		s_cyl.material = mat_titanium
		strut.mesh = s_cyl
		strut.position = (leg_dir * 0.85 + Vector3(0.0, 0.45, 0.0))
		strut.rotation_degrees = Vector3(-35 * sin(angle), -rad_to_deg(angle), 35 * cos(angle))
		leg_root.add_child(strut)

		# Footpad
		var footpad = MeshInstance3D.new()
		footpad.name = "Footpad_%d" % (i + 1)
		var f_cyl = CylinderMesh.new()
		f_cyl.top_radius = 0.16
		f_cyl.bottom_radius = 0.16
		f_cyl.height = 0.05
		f_cyl.material = mat_alu
		footpad.mesh = f_cyl
		footpad.position = foot_pos
		_attach_component_info(footpad, "Aluminum Honeycomb Footpad %d" % (i + 1), "30cm circular footpad with internal crushable honeycomb core to absorb landing shock.", "Diameter: 30 cm | Penetration depth: ~3 to 8 cm")
		leg_root.add_child(footpad)

	# Dual SNAP-19 Radioisotope Thermoelectric Generators (RTGs) - NO SOLAR PANELS
	for i in [-1, 1]:
		var rtg = MeshInstance3D.new()
		rtg.name = "SNAP19_RTG_%s" % ("Port" if i < 0 else "Starboard")
		var r_cyl = CylinderMesh.new()
		r_cyl.top_radius = 0.18
		r_cyl.bottom_radius = 0.18
		r_cyl.height = 0.35
		r_cyl.radial_segments = 12
		r_cyl.material = mat_rtg
		rtg.mesh = r_cyl
		rtg.position = Vector3(float(i) * 0.45, 1.05, -0.25)
		_attach_component_info(rtg, "SNAP-19 RTG Power Generator", "Plutonium-238 radioisotope thermoelectric generator providing 57W continuous electrical power day and night.", "Fuel: Pu-238 dioxide | Output: 57 W continuous | NO solar panels")
		root.add_child(rtg)

	# Dual Facsimile Scanning Cameras
	for i in [-0.4, 0.4]:
		var cam = MeshInstance3D.new()
		cam.name = "FacsimileScanningCamera"
		var c_cyl = CylinderMesh.new()
		c_cyl.top_radius = 0.06
		c_cyl.bottom_radius = 0.06
		c_cyl.height = 0.32
		c_cyl.material = mat_white
		cam.mesh = c_cyl
		cam.position = Vector3(i, 1.15, 0.35)
		_attach_component_info(cam, "Facsimile Scanning Camera", "Optomechanical scanning sensor rotating line-by-line to capture iconic early surface panoramas.", "Array: 12 photodiodes | Resolution: up to 1000 lines")
		root.add_child(cam)

	# Telescoping Surface Sampler Arm
	var arm = Node3D.new()
	arm.name = "SurfaceSamplerBoom"
	_attach_component_info(arm, "Telescoping Surface Sampler Boom", "3.0m retractable boom with backhoe scoop and sieve that dug trenches in Martian soil.", "Reach: 3.0 m | Elevation: +40° to -60°")
	root.add_child(arm)

	var arm_tube = MeshInstance3D.new()
	var at_cyl = CylinderMesh.new()
	at_cyl.top_radius = 0.025
	at_cyl.bottom_radius = 0.025
	at_cyl.height = 1.45
	at_cyl.material = mat_alu
	arm_tube.mesh = at_cyl
	arm_tube.position = Vector3(0.0, 0.50, 0.95)
	arm_tube.rotation_degrees = Vector3(-45, 0, 0)
	arm.add_child(arm_tube)

	var scoop = MeshInstance3D.new()
	scoop.name = "SoilBackhoeScoop"
	var sc_box = BoxMesh.new()
	sc_box.size = Vector3(0.12, 0.08, 0.16)
	sc_box.material = mat_titanium
	scoop.mesh = sc_box
	scoop.position = Vector3(0.0, 0.06, 1.55)
	_attach_component_info(scoop, "Soil Collector Scoop & Sieve", "Backhoe scoop with motorized jaw and vibration sieve to deliver regolith to onboard biology funnels.", "Volume: ~50 cc | Sieve mesh: 2 mm")
	arm.add_child(scoop)

	# S-Band High-Gain Antenna Dish
	var dish = MeshInstance3D.new()
	dish.name = "S_BandHighGainAntenna"
	var d_cyl = CylinderMesh.new()
	d_cyl.top_radius = 0.38
	d_cyl.bottom_radius = 0.08
	d_cyl.height = 0.09
	d_cyl.material = mat_white
	dish.mesh = d_cyl
	dish.position = Vector3(0.0, 1.35, 0.0)
	dish.rotation_degrees = Vector3(25, 30, 0)
	_attach_component_info(dish, "S-Band High-Gain Dish", "76cm parabolic steerable dish antenna communicating directly with Earth at S-band frequencies.", "Diameter: 76 cm | Frequency: 2.29 GHz (S-band)")
	root.add_child(dish)

	return root

# 5. Phoenix Mars Lander (Vastitas Borealis: 68.22° N, 234.25° E)
# Height: 2.2m, Deployed solar span: 5.52m, Mass: 350 kg
static func build_phoenix_lander(dust_level: float = 0.40) -> Node3D:
	var root = Node3D.new()
	root.name = "PhoenixLander"
	_attach_component_info(root, "Phoenix Mars Lander", "Stationary polar explorer; verified subsurface water ice in Vastitas Borealis (2008).", "Landed mass: 350 kg | Solar span: 5.52 m | Target: Permafrost water ice")

	var mat_alu = get_material("aluminum_anodized", dust_level)
	var mat_gold = get_material("gold_kapton_mli", dust_level)
	var mat_solar = get_material("solar_cell_silicon", dust_level * 0.9)
	var mat_titanium = get_material("titanium", dust_level)
	var mat_frost = get_material("permafrost_frost", 0.0)

	# Main Lander Deck
	var deck = MeshInstance3D.new()
	deck.name = "LanderMainDeck"
	var d_cyl = CylinderMesh.new()
	d_cyl.radial_segments = 8
	d_cyl.top_radius = 0.78
	d_cyl.bottom_radius = 0.78
	d_cyl.height = 0.35
	d_cyl.material = mat_gold
	deck.mesh = d_cyl
	deck.position = Vector3(0.0, 0.65, 0.0)
	_attach_component_info(deck, "Science Equipment Deck", "Contains TEGA sample ovens, MECA chemistry cells, descent computer, and radar altimeter.", "Diameter: 1.5 m | Insulation: Multi-layer Kapton")
	root.add_child(deck)

	# 3 Inverted Tripod Landing Legs
	for i in range(3):
		var angle = float(i) * 120.0 * (PI / 180.0)
		var foot_dir = Vector3(cos(angle), 0.0, sin(angle))
		var leg = MeshInstance3D.new()
		var l_cyl = CylinderMesh.new()
		l_cyl.top_radius = 0.03
		l_cyl.bottom_radius = 0.03
		l_cyl.height = 0.95
		l_cyl.material = mat_titanium
		leg.mesh = l_cyl
		leg.position = foot_dir * 0.70 + Vector3(0.0, 0.38, 0.0)
		leg.rotation_degrees = Vector3(-32 * sin(angle), -rad_to_deg(angle), 32 * cos(angle))
		root.add_child(leg)

		var footpad = MeshInstance3D.new()
		footpad.name = "PolarFootpad_%d" % (i + 1)
		var f_cyl = CylinderMesh.new()
		f_cyl.top_radius = 0.15
		f_cyl.bottom_radius = 0.15
		f_cyl.height = 0.04
		f_cyl.material = mat_alu
		footpad.mesh = f_cyl
		footpad.position = foot_dir * 1.30 + Vector3(0.0, 0.04, 0.0)
		root.add_child(footpad)

	# Two Circular Decagonal Solar Wings (Span: 5.52m, Diameter: 2.09m each)
	for i in [-1, 1]:
		var wing = MeshInstance3D.new()
		wing.name = "DecagonalSolarArray_%s" % ("East" if i > 0 else "West")
		var w_cyl = CylinderMesh.new()
		w_cyl.radial_segments = 10
		w_cyl.top_radius = 1.05
		w_cyl.bottom_radius = 1.05
		w_cyl.height = 0.03
		w_cyl.material = mat_solar
		wing.mesh = w_cyl
		wing.position = Vector3(float(i) * 1.95, 0.72, 0.0)
		_attach_component_info(wing, "10-Sided Decagonal Solar Array", "2.09m diameter circular unfolding solar array generating 750 Wh/sol at landing.", "Diameter: 2.09 m | Total span: 5.52 m | Cells: High-efficiency GaAs")
		root.add_child(wing)

	# Robotic Excavation Arm (2.35m long with rasp blade and scoop)
	var arm = Node3D.new()
	arm.name = "PolarExcavationArm"
	_attach_component_info(arm, "Robotic Excavation Arm (RA)", "2.35m carbon-composite arm with motorized rasp blade to dig into rock-hard polar water-ice permafrost.", "Length: 2.35 m | DOF: 4 | Dig depth: up to 0.5 m")
	root.add_child(arm)

	var arm_bone = MeshInstance3D.new()
	var b_cyl = CylinderMesh.new()
	b_cyl.top_radius = 0.03
	b_cyl.bottom_radius = 0.03
	b_cyl.height = 1.20
	b_cyl.material = mat_titanium
	arm_bone.mesh = b_cyl
	arm_bone.position = Vector3(0.0, 0.40, 0.75)
	arm_bone.rotation_degrees = Vector3(-45, 0, 0)
	arm.add_child(arm_bone)

	var scoop = MeshInstance3D.new()
	scoop.name = "IceRaspScoop"
	var sc_box = BoxMesh.new()
	sc_box.size = Vector3(0.14, 0.10, 0.18)
	sc_box.material = mat_titanium
	scoop.mesh = sc_box
	scoop.position = Vector3(0.0, 0.08, 1.28)
	_attach_component_info(scoop, "Permafrost Scoop & Rasp Blade", "Carbide rotary rasp capable of cutting into frozen subterranean water-ice sheets.", "Rasp speed: 300 RPM | Blade: Tungsten carbide")
	arm.add_child(scoop)

	# Surface Stereo Imager (SSI) Mast & MET Lidar
	var ssi = MeshInstance3D.new()
	ssi.name = "SurfaceStereoImager_SSI"
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 0.03
	s_cyl.bottom_radius = 0.03
	s_cyl.height = 0.95
	s_cyl.material = mat_alu
	ssi.mesh = s_cyl
	ssi.position = Vector3(-0.25, 1.25, -0.20)
	_attach_component_info(ssi, "Surface Stereo Imager (SSI)", "Mast-mounted stereo panoramic imager identical to MER Pancam with 12 optical filters.", "Height: 2.2 m above ground | Resolution: 1024x1024")
	root.add_child(ssi)

	var tega = MeshInstance3D.new()
	tega.name = "TEGA_Ovens"
	var t_box = BoxMesh.new()
	t_box.size = Vector3(0.28, 0.12, 0.28)
	t_box.material = mat_alu
	tega.mesh = t_box
	tega.position = Vector3(0.20, 0.86, 0.15)
	_attach_component_info(tega, "TEGA Miniature Ovens", "8 single-use micro-ovens that heated permafrost samples to 1000°C to release water vapor.", "Ovens: 8 | Max temp: 1,000°C | Mass spectrometer detector")
	root.add_child(tega)

	return root

# 6. InSight Mars Lander (Elysium Planitia: 4.50° N, 135.62° E)
# Height: 1.08m, Solar span: 6.0m, Mass: 358 kg
static func build_insight_lander(dust_level: float = 0.70) -> Node3D:
	var root = Node3D.new()
	root.name = "InSightLander"
	_attach_component_info(root, "InSight Mars Lander", "Interior exploration geophysics station stationed in Elysium Planitia (2018–2022).", "Landed mass: 358 kg | Solar span: 6.0 m | Payloads: SEIS, HP3, RISE")

	var mat_alu = get_material("aluminum_anodized", dust_level)
	var mat_gold = get_material("gold_kapton_mli", dust_level)
	var mat_solar = get_material("solar_cell_silicon", dust_level * 0.95)
	var mat_titanium = get_material("titanium", dust_level)
	var mat_cable = get_material("carbon_fiber", dust_level * 0.8)

	# Main Circular Lander Deck
	var deck = MeshInstance3D.new()
	deck.name = "LanderMainDeck"
	var d_cyl = CylinderMesh.new()
	d_cyl.top_radius = 0.78
	d_cyl.bottom_radius = 0.78
	d_cyl.height = 0.32
	d_cyl.material = mat_gold
	deck.mesh = d_cyl
	deck.position = Vector3(0.0, 0.62, 0.0)
	_attach_component_info(deck, "InSight Avionics Deck", "Houses RAD750 computer, UHF transceiver, descent helium tanks, and science instrument electronics.", "Diameter: 1.56 m | Mass: 358 kg")
	root.add_child(deck)

	# 3 Landing Legs with Footpads
	for i in range(3):
		var angle = float(i) * 120.0 * (PI / 180.0)
		var foot_dir = Vector3(cos(angle), 0.0, sin(angle))
		var leg = MeshInstance3D.new()
		var l_cyl = CylinderMesh.new()
		l_cyl.top_radius = 0.035
		l_cyl.bottom_radius = 0.035
		l_cyl.height = 0.90
		l_cyl.material = mat_titanium
		leg.mesh = l_cyl
		leg.position = foot_dir * 0.65 + Vector3(0.0, 0.35, 0.0)
		leg.rotation_degrees = Vector3(-35 * sin(angle), -rad_to_deg(angle), 35 * cos(angle))
		root.add_child(leg)

		var footpad = MeshInstance3D.new()
		footpad.name = "InSightFootpad_%d" % (i + 1)
		var f_cyl = CylinderMesh.new()
		f_cyl.top_radius = 0.15
		f_cyl.bottom_radius = 0.15
		f_cyl.height = 0.04
		f_cyl.material = mat_alu
		footpad.mesh = f_cyl
		footpad.position = foot_dir * 1.25 + Vector3(0.0, 0.04, 0.0)
		root.add_child(footpad)

	# Two 10-sided UltraFlex Solar Array Wings (Diameter: 2.15m each, Span: 6.0m)
	for i in [-1, 1]:
		var array = MeshInstance3D.new()
		array.name = "UltraFlexSolarArray_%s" % ("Port" if i < 0 else "Starboard")
		var a_cyl = CylinderMesh.new()
		a_cyl.radial_segments = 10
		a_cyl.top_radius = 1.08
		a_cyl.bottom_radius = 1.08
		a_cyl.height = 0.02
		a_cyl.material = mat_solar
		array.mesh = a_cyl
		array.position = Vector3(float(i) * 2.15, 0.68, 0.0)
		_attach_component_info(array, "UltraFlex Decagonal Solar Array", "2.15m diameter accordion-deployed circular solar wing, heavily covered in Martian dust.", "Diameter: 2.15 m each | Total span: 6.0 m | Initial power: 4.5 kWh/sol")
		root.add_child(array)

	# Instrument Deployment Arm (IDA - 1.8m)
	var ida = Node3D.new()
	ida.name = "InstrumentDeploymentArm_IDA"
	_attach_component_info(ida, "Instrument Deployment Arm (IDA)", "1.8m articulated robotic arm with five-finger wax grapple that placed SEIS and HP3 on the surface.", "Length: 1.8 m | DOF: 4 | Grapple: Wax thermal actuator")
	root.add_child(ida)

	var arm_tube = MeshInstance3D.new()
	var at_cyl = CylinderMesh.new()
	at_cyl.top_radius = 0.025
	at_cyl.bottom_radius = 0.025
	at_cyl.height = 1.10
	at_cyl.material = mat_alu
	arm_tube.mesh = at_cyl
	arm_tube.position = Vector3(0.0, 0.45, 0.65)
	arm_tube.rotation_degrees = Vector3(-45, 0, 0)
	ida.add_child(arm_tube)

	# SEIS (Seismic Experiment for Interior Structure) with Wind and Thermal Shield (WTS) on ground
	var seis = Node3D.new()
	seis.name = "SEIS_WindThermalShield"
	seis.position = Vector3(0.85, 0.0, 1.35)
	_attach_component_info(seis, "SEIS Seismometer & WTS Dome", "Ultra-sensitive French CNES seismometer beneath an aerodynamic gold thermal and wind shield.", "Sensitivity: Pico-meter ground vibrations | Recorded >1300 marsquakes")
	root.add_child(seis)

	var dome = MeshInstance3D.new()
	dome.name = "WTS_AerodynamicDome"
	var d_mesh = SphereMesh.new()
	d_mesh.radius = 0.35
	d_mesh.height = 0.32
	d_mesh.radial_segments = 16
	d_mesh.material = mat_gold
	dome.mesh = d_mesh
	dome.position = Vector3(0.0, 0.16, 0.0)
	seis.add_child(dome)

	# Ribbon Tether Cable running from lander deck to SEIS dome
	var cable = MeshInstance3D.new()
	cable.name = "SEIS_TetherRibbonCable"
	var c_box = BoxMesh.new()
	c_box.size = Vector3(0.08, 0.01, 1.45)
	c_box.material = mat_cable
	cable.mesh = c_box
	cable.position = Vector3(0.42, 0.02, 0.70)
	cable.rotation_degrees = Vector3(0, -32, 0)
	_attach_component_info(cable, "SEIS Flexible Ribbon Cable", "Flat multi-conductor cable with thermal Mylar shield transmitting seismic analog signals.", "Conductors: 128 traces | Mylar thermal shield")
	root.add_child(cable)

	# HP3 "The Mole" Heat Flow Probe resting structure on ground
	var hp3 = MeshInstance3D.new()
	hp3.name = "HP3_MoleSupportStructure"
	var hp_box = BoxMesh.new()
	hp_box.size = Vector3(0.24, 0.28, 0.32)
	hp_box.material = mat_alu
	hp3.mesh = hp_box
	hp3.position = Vector3(-0.95, 0.14, 1.15)
	_attach_component_info(hp3, "HP3 Heat Flow Probe ('The Mole')", "German DLR self-hammering heat probe; penetrated 37cm before halting due to soil friction.", "Intended depth: 5 m | Actual depth: 37 cm | Status: Retired")
	root.add_child(hp3)

	# RISE Horn Antennas and TWINS weather booms
	for i in [-0.3, 0.3]:
		var horn = MeshInstance3D.new()
		horn.name = "RISE_XBandHorn"
		var h_cyl = CylinderMesh.new()
		h_cyl.top_radius = 0.06
		h_cyl.bottom_radius = 0.02
		h_cyl.height = 0.14
		h_cyl.material = mat_alu
		horn.mesh = h_cyl
		horn.position = Vector3(i, 0.85, -0.35)
		_attach_component_info(horn, "RISE X-Band Horn Antenna", "Measures planetary precession and nutation of Mars's core with millimeter-precision Doppler tracking.", "Tracking: DSN Doppler shift | Core state: Liquid core confirmed")
		root.add_child(horn)

	return root

# 7. Ingenuity Mars Helicopter (Jezero Crater - Valinor Hills: 18.44° N, 77.45° E)
# Height: 0.49m, Rotor diameter: 1.21m, Mass: 1.8 kg
static func build_ingenuity_helicopter(damaged_blade: bool = true, dust_level: float = 0.30) -> Node3D:
	var root = Node3D.new()
	root.name = "IngenuityHelicopter"
	_attach_component_info(root, "Ingenuity Mars Helicopter", "First powered controlled aircraft on another planet (Mars 2020 Perseverance mission).", "Rotor diameter: 1.21 m | Total mass: 1.80 kg | Flights completed: 72")

	var mat_carbon = get_material("carbon_fiber", dust_level)
	var mat_gold = get_material("gold_kapton_mli", dust_level)
	var mat_solar = get_material("solar_cell_silicon", dust_level * 0.8)
	var mat_alu = get_material("aluminum_anodized", dust_level)
	var mat_lens = get_material("optical_glass", 0.0)

	# Fuselage Body Box (17 x 14 x 14 cm)
	var fuselage = MeshInstance3D.new()
	fuselage.name = "FuselageCore"
	var f_box = BoxMesh.new()
	f_box.size = Vector3(0.195, 0.163, 0.136)
	f_box.material = mat_gold
	fuselage.mesh = f_box
	fuselage.position = Vector3(0.0, 0.22, 0.0)
	_attach_component_info(fuselage, "Lightweight Fuselage Core", "Insulated warm box housing Qualcomm Snapdragon 801 CPU, 6 Sony Li-ion cells (35.7 Wh), and IMU.", "Mass: ~1.0 kg | Battery: 6x Li-ion (35.7 Wh) | CPU: Snapdragon 801")
	root.add_child(fuselage)

	# 4 Splayed Carbon-Fiber Landing Legs (Length: 0.384m)
	for i in range(4):
		var angle = float(i * 90 + 45) * (PI / 180.0)
		var leg_dir = Vector3(cos(angle), 0.0, sin(angle))
		var leg = MeshInstance3D.new()
		leg.name = "CarbonCompositeLeg_%d" % (i + 1)
		var l_cyl = CylinderMesh.new()
		l_cyl.top_radius = 0.007
		l_cyl.bottom_radius = 0.007
		l_cyl.height = 0.384
		l_cyl.material = mat_carbon
		leg.mesh = l_cyl
		leg.position = leg_dir * 0.18 + Vector3(0.0, 0.11, 0.0)
		leg.rotation_degrees = Vector3(-35 * sin(angle), -rad_to_deg(angle), 35 * cos(angle))
		_attach_component_info(leg, "Carbon-Composite Landing Leg %d" % (i + 1), "0.384m hollow carbon-fiber tube with compliance flexures to absorb touchdown impact.", "Length: 38.4 cm | Material: Carbon-fiber composite")
		root.add_child(leg)

	# Vertical Rotor Mast
	var mast = MeshInstance3D.new()
	mast.name = "CoaxialRotorMast"
	var m_cyl = CylinderMesh.new()
	m_cyl.top_radius = 0.02
	m_cyl.bottom_radius = 0.02
	m_cyl.height = 0.28
	m_cyl.material = mat_alu
	mast.mesh = m_cyl
	mast.position = Vector3(0.0, 0.36, 0.0)
	root.add_child(mast)

	# Lower and Upper Counter-Rotating Coaxial Rotors (Diameter: 1.21 m)
	var rotor_heights = [0.35, 0.44]
	for r_idx in range(2):
		var r_y = rotor_heights[r_idx]
		var rotor_hub = Node3D.new()
		rotor_hub.name = "CoaxialRotor_%s" % ("Lower" if r_idx == 0 else "Upper")
		rotor_hub.position = Vector3(0.0, r_y, 0.0)
		root.add_child(rotor_hub)

		var hub_mesh = MeshInstance3D.new()
		var h_cyl = CylinderMesh.new()
		h_cyl.top_radius = 0.038
		h_cyl.bottom_radius = 0.038
		h_cyl.height = 0.035
		h_cyl.material = mat_alu
		hub_mesh.mesh = h_cyl
		rotor_hub.add_child(hub_mesh)

		# Two blades per rotor hub
		for b_idx in [-1, 1]:
			var blade = MeshInstance3D.new()
			var blade_num = (r_idx * 2) + (1 if b_idx > 0 else 2)
			blade.name = "CarbonFiberBlade_%d" % blade_num
			var is_damaged_blade = (damaged_blade and r_idx == 1 and b_idx == 1)

			var b_mesh = BoxMesh.new()
			# If damaged on Flight 72 at Valinor Hills, blade tip is broken ~15cm short
			var blade_len = 0.42 if is_damaged_blade else 0.58
			b_mesh.size = Vector3(blade_len, 0.008, 0.075)
			b_mesh.material = mat_carbon
			blade.mesh = b_mesh

			var offset_x = float(b_idx) * (blade_len * 0.5 + 0.04)
			blade.position = Vector3(offset_x, 0.0, 0.0)
			blade.rotation_degrees = Vector3(float(b_idx) * 8.0, 0.0, 0.0)

			if is_damaged_blade:
				_attach_component_info(blade, "Damaged Carbon-Fiber Blade 4", "Rotor blade tip sustained fracture during hard landing on Flight 72 (Jan 18, 2024).", "Status: Tip fractured (~15 cm lost) | Ended flight operations")
			else:
				_attach_component_info(blade, "Carbon-Composite Blade %d" % blade_num, "High-efficiency foam-core carbon-fiber blade designed for 2700 RPM lift in thin CO2 air.", "Rotor span: 1.21 m | RPM: 2400-2700 | Airfoil: Custom low-Re")
			rotor_hub.add_child(blade)

	# Solar Panel Deck (Mounted horizontally above the upper rotor)
	var solar = MeshInstance3D.new()
	solar.name = "RotorTopSolarPanel"
	var s_box = BoxMesh.new()
	s_box.size = Vector3(0.24, 0.012, 0.16)
	s_box.material = mat_solar
	solar.mesh = s_box
	solar.position = Vector3(0.0, 0.49, 0.0)
	_attach_component_info(solar, "Upper Solar Array Panel", "Small 0.06 m² solar panel mounted above the rotor head to recharge Li-ion batteries each sol.", "Area: 0.06 m² | Daily yield: ~10 Wh/sol")
	root.add_child(solar)

	# Downward-Facing Navigation Camera
	var navcam = MeshInstance3D.new()
	navcam.name = "DownwardNavigationCamera"
	var n_cyl = CylinderMesh.new()
	n_cyl.top_radius = 0.015
	n_cyl.bottom_radius = 0.015
	n_cyl.height = 0.03
	n_cyl.material = mat_lens
	navcam.mesh = n_cyl
	navcam.position = Vector3(0.0, 0.12, 0.0)
	navcam.rotation_degrees = Vector3(180, 0, 0)
	_attach_component_info(navcam, "Downward Visual Navigation Camera", "Captures 30 FPS ground images to track optical visual odometry velocity and displacement.", "Resolution: 640x480 | Frame rate: 30 FPS")
	root.add_child(navcam)

	return root

# ==============================================================================
# PART 2: SPACECRAFT FROM OTHER DESTINATIONS (SOLAR SYSTEM COLLECTION)
# ==============================================================================

# 8. Dawn Spacecraft (Ceres Orbit)
# Core: 1.64m x 1.27m x 1.77m, Solar Wingspan: 19.70m, Mass: 1,217.7 kg
static func build_dawn_spacecraft() -> Node3D:
	var root = Node3D.new()
	root.name = "DawnSpacecraft"
	_attach_component_info(root, "Dawn Spacecraft", "NASA asteroid orbiter that explored 4 Vesta and dwarf planet 1 Ceres (2007–2018).", "Wingspan: 19.7 m | Dry mass: 747 kg | Propulsion: 3x NSTAR Xenon Ion Engines")

	var mat_alu = get_material("aluminum_anodized", 0.0)
	var mat_gold = get_material("gold_kapton_mli", 0.0)
	var mat_solar = get_material("solar_cell_silicon", 0.0)
	var mat_lens = get_material("optical_glass", 0.0)

	# Central Bus Box (1.64 x 1.27 x 1.77 m)
	var bus = MeshInstance3D.new()
	bus.name = "SpacecraftCentralBus"
	var b_box = BoxMesh.new()
	b_box.size = Vector3(1.64, 1.77, 1.27)
	b_box.material = mat_gold
	bus.mesh = b_box
	_attach_component_info(bus, "Central Spacecraft Bus", "Graphite composite bus housing Xenon fuel tank (425 kg) and science data processors.", "Dimensions: 1.64 x 1.77 x 1.27 m | Xenon load: 425 kg")
	root.add_child(bus)

	# Enormous 5-Panel Rectangular Solar Array Wings (Total Wingspan: 19.70 m)
	for i in [-1, 1]:
		var wing = MeshInstance3D.new()
		wing.name = "SolarArrayWing_%s" % ("Port" if i < 0 else "Starboard")
		var w_box = BoxMesh.new()
		w_box.size = Vector3(8.30, 0.04, 2.30)
		w_box.material = mat_solar
		wing.mesh = w_box
		wing.position = Vector3(float(i) * 5.75, 0.0, 0.0)
		_attach_component_info(wing, "Deployable Solar Array Wing", "8.3m x 2.3m 5-panel solar array. Total span 19.7m to harvest faint sunlight at 3 AU at Ceres.", "Span: 19.7 m | Area: 36.4 m² | Power: 10 kW at 1 AU, 1.3 kW at Ceres")
		root.add_child(wing)

	# High-Gain Antenna (HGA - 1.52m parabolic dish)
	var hga = MeshInstance3D.new()
	hga.name = "HighGainAntennaDish"
	var d_cyl = CylinderMesh.new()
	d_cyl.top_radius = 0.76
	d_cyl.bottom_radius = 0.12
	d_cyl.height = 0.18
	d_cyl.material = mat_alu
	hga.mesh = d_cyl
	hga.position = Vector3(0.0, 0.0, 0.72)
	hga.rotation_degrees = Vector3(90, 0, 0)
	_attach_component_info(hga, "High-Gain Antenna (HGA)", "1.52m parabolic dish transmitting Ceres and Vesta mapping data to NASA's Deep Space Network.", "Diameter: 1.52 m | Frequency: X-band")
	root.add_child(hga)

	# 3 Aft NSTAR Xenon Ion Thrusters (NO ACTIVE FLAMES)
	for i in [-0.35, 0.0, 0.35]:
		var thruster = MeshInstance3D.new()
		thruster.name = "NSTAR_IonThruster"
		var t_cyl = CylinderMesh.new()
		t_cyl.top_radius = 0.15
		t_cyl.bottom_radius = 0.08
		t_cyl.height = 0.22
		t_cyl.material = mat_alu
		thruster.mesh = t_cyl
		thruster.position = Vector3(i, -0.98, 0.0)
		_attach_component_info(thruster, "NSTAR Xenon Ion Engine", "Electrostatic ion thruster accelerating ionized Xenon at 31 km/s with Isp of 3,100 seconds.", "Thrust: 19–91 mN | Specific impulse: 3,100 s | Unpowered/inactive")
		root.add_child(thruster)

	return root

# 9. NEAR Shoemaker (Asteroid 433 Eros)
# Body: 1.7m octagonal prism x 2.8m, 4 windmill solar panels, Mass: 805 kg
static func build_near_shoemaker() -> Node3D:
	var root = Node3D.new()
	root.name = "NEAR_Shoemaker"
	_attach_component_info(root, "NEAR Shoemaker", "First spacecraft to orbit and softly land on an asteroid (433 Eros, 2001).", "Body: 1.7m octagonal prism | Landed mass: 487 kg | Rested on solar panel tips")

	var mat_alu = get_material("aluminum_anodized", 0.0)
	var mat_solar = get_material("solar_cell_gaas", 0.0)
	var mat_gold = get_material("gold_kapton_mli", 0.0)

	# Octagonal Prism Body
	var body = MeshInstance3D.new()
	body.name = "OctagonalPrismBody"
	var o_cyl = CylinderMesh.new()
	o_cyl.radial_segments = 8
	o_cyl.top_radius = 0.85
	o_cyl.bottom_radius = 0.85
	o_cyl.height = 1.70
	o_cyl.material = mat_gold
	body.mesh = o_cyl
	body.position = Vector3(0.0, 1.25, 0.0)
	_attach_component_info(body, "Octagonal Equipment Bus", "1.7m octagonal frame housing hydrazine thrusters, attitude gyros, and science avionics.", "Structure: Octagonal prism | Length: 2.8 m with dish")
	root.add_child(body)

	# 4 Windmill-Pattern Fixed Solar Panels (1.8m x 1.2m each) - Resting on tips
	var panel_offsets = [
		Vector3(1.45, 1.25, 0.0),
		Vector3(-1.45, 1.25, 0.0),
		Vector3(0.0, 1.25, 1.45),
		Vector3(0.0, 1.25, -1.45)
	]
	var panel_rotations = [
		Vector3(0, 0, 15),
		Vector3(0, 0, -15),
		Vector3(-15, 0, 0),
		Vector3(15, 0, 0)
	]
	for i in range(4):
		var panel = MeshInstance3D.new()
		panel.name = "WindmillSolarPanel_%d" % (i + 1)
		var p_box = BoxMesh.new()
		p_box.size = Vector3(1.80, 0.03, 1.20)
		p_box.material = mat_solar
		panel.mesh = p_box
		panel.position = panel_offsets[i]
		panel.rotation_degrees = panel_rotations[i]
		_attach_component_info(panel, "Windmill Solar Array %d" % (i + 1), "Fixed GaAs solar panel. Upon landing on Eros (Feb 2001), NEAR rested on these panel edges.", "Dimensions: 1.8 x 1.2 m each | NO landing legs | Output: 1,800 W at 1 AU")
		root.add_child(panel)

	# 1.50m High-Gain X-Band Dish Antenna
	var dish = MeshInstance3D.new()
	dish.name = "HighGainDishAntenna"
	var d_cyl = CylinderMesh.new()
	d_cyl.top_radius = 0.75
	d_cyl.bottom_radius = 0.10
	d_cyl.height = 0.16
	d_cyl.material = mat_alu
	dish.mesh = d_cyl
	dish.position = Vector3(0.0, 2.25, 0.0)
	_attach_component_info(dish, "Fixed High-Gain X-Band Dish", "1.5m fixed parabolic dish antenna communicating asteroid laser altimetry and multispectral data.", "Diameter: 1.5 m | Direct to DSN")
	root.add_child(dish)

	# Magnetometer Boom (1.2m)
	var mag = MeshInstance3D.new()
	mag.name = "MagnetometerBoom"
	var m_cyl = CylinderMesh.new()
	m_cyl.top_radius = 0.015
	m_cyl.bottom_radius = 0.015
	m_cyl.height = 1.20
	m_cyl.material = mat_alu
	mag.mesh = m_cyl
	mag.position = Vector3(0.65, 2.10, 0.0)
	mag.rotation_degrees = Vector3(0, 0, -45)
	_attach_component_info(mag, "Magnetometer Boom", "1.2m boom extending fluxgate magnetometer to isolate sensor from spacecraft magnetic noise.", "Instrument: Triaxial fluxgate magnetometer")
	root.add_child(mag)

	return root

# 10. Pioneer 10 & Pioneer 11 Probes (Deep Space / Interstellar Probes)
# 2.74m Parabolic Dish, Hexagonal Bus, RTG Booms, Pioneer Plaque
static func build_pioneer_probe(pioneer_num: int = 10) -> Node3D:
	var root = Node3D.new()
	root.name = "Pioneer%d" % pioneer_num
	var target = "Jupiter & Aldebaran trajectory" if pioneer_num == 10 else "Saturn & Aquila trajectory"
	_attach_component_info(root, "Pioneer %d Probe" % pioneer_num, "Spin-stabilized deep space probe carrying the famous golden Pioneer Plaque to the stars.", "Antenna diameter: 2.74 m | Mass: 258 kg | Destination: %s" % target)

	var mat_alu = get_material("aluminum_anodized", 0.0)
	var mat_gold = get_material("gold_kapton_mli", 0.0)
	var mat_rtg = get_material("rtg_casing", 0.0)
	var mat_plaque = get_material("gold_kapton_mli", 0.0)

	# Prominent 2.74m Parabolic High-Gain Dish Antenna
	var dish = MeshInstance3D.new()
	dish.name = "HighGainParabolicDish"
	var d_cyl = CylinderMesh.new()
	d_cyl.top_radius = 1.37
	d_cyl.bottom_radius = 0.20
	d_cyl.height = 0.38
	d_cyl.radial_segments = 24
	d_cyl.material = mat_alu
	dish.mesh = d_cyl
	dish.position = Vector3(0.0, 0.0, 0.0)
	dish.rotation_degrees = Vector3(90, 0, 0)
	_attach_component_info(dish, "2.74m High-Gain Parabolic Dish", "Large aluminum honeycomb reflector dish providing S-band communications across billions of kilometers.", "Diameter: 2.74 m (9.0 ft) | Frequency: S-band (2.1–2.3 GHz)")
	root.add_child(dish)

	# Feed Horn Tripod
	var feed = MeshInstance3D.new()
	var f_cyl = CylinderMesh.new()
	f_cyl.top_radius = 0.06
	f_cyl.bottom_radius = 0.06
	f_cyl.height = 0.65
	f_cyl.material = mat_alu
	feed.mesh = f_cyl
	feed.position = Vector3(0.0, 0.0, 0.55)
	feed.rotation_degrees = Vector3(90, 0, 0)
	root.add_child(feed)

	# Hexagonal Equipment Compartment (Behind the dish)
	var hex_bus = MeshInstance3D.new()
	hex_bus.name = "HexagonalEquipmentCompartment"
	var h_cyl = CylinderMesh.new()
	h_cyl.radial_segments = 6
	h_cyl.top_radius = 0.76
	h_cyl.bottom_radius = 0.76
	h_cyl.height = 0.36
	h_cyl.material = mat_gold
	hex_bus.mesh = h_cyl
	hex_bus.position = Vector3(0.0, 0.0, -0.36)
	hex_bus.rotation_degrees = Vector3(90, 0, 0)
	_attach_component_info(hex_bus, "Hexagonal Equipment Bus", "36cm deep hexagonal electronics chassis housing scientific instruments, star sensor, and hydrazine tanks.", "Depth: 36 cm | Width: 76 cm | Spin-stabilized: 4.8 RPM")
	root.add_child(hex_bus)

	# Dual SNAP-19 RTG Power Truss Booms (NO SOLAR PANELS)
	for i in [-1, 1]:
		var rtg_boom = Node3D.new()
		rtg_boom.name = "RTG_TrussBoom_%s" % ("Port" if i < 0 else "Starboard")
		rtg_boom.rotation_degrees = Vector3(0, 0, float(i) * 60)
		root.add_child(rtg_boom)

		var truss = MeshInstance3D.new()
		var t_cyl = CylinderMesh.new()
		t_cyl.top_radius = 0.02
		t_cyl.bottom_radius = 0.02
		t_cyl.height = 2.40
		t_cyl.material = mat_alu
		truss.mesh = t_cyl
		truss.position = Vector3(1.40, 0.0, -0.36)
		truss.rotation_degrees = Vector3(0, 0, 90)
		rtg_boom.add_child(truss)

		var rtg = MeshInstance3D.new()
		var r_cyl = CylinderMesh.new()
		r_cyl.top_radius = 0.16
		r_cyl.bottom_radius = 0.16
		r_cyl.height = 0.45
		r_cyl.material = mat_rtg
		rtg.mesh = r_cyl
		rtg.position = Vector3(2.65, 0.0, -0.36)
		_attach_component_info(rtg, "SNAP-19 RTGs (Pair)", "Plutonium-238 RTG pair powering the probe in deep space where sunlight is too faint for solar cells.", "Output: 155 W at launch | NO solar arrays | Fuel: Pu-238")
		rtg_boom.add_child(rtg)

	# Deployable Magnetometer Boom (6.6m)
	var mag_boom = MeshInstance3D.new()
	mag_boom.name = "MagnetometerBoom_6_6m"
	var mb_cyl = CylinderMesh.new()
	mb_cyl.top_radius = 0.015
	mb_cyl.bottom_radius = 0.015
	mb_cyl.height = 4.50
	mb_cyl.material = mat_alu
	mag_boom.mesh = mb_cyl
	mag_boom.position = Vector3(0.0, -2.40, -0.36)
	mag_boom.rotation_degrees = Vector3(0, 0, 0)
	_attach_component_info(mag_boom, "Magnetometer Boom", "Long deployable boom placing helium vector magnetometer away from spacecraft electronics.", "Length: 6.6 m | Instrument: Helium vector magnetometer")
	root.add_child(mag_boom)

	# Famous Pioneer Plaque (Golden anodized aluminum)
	var plaque = MeshInstance3D.new()
	plaque.name = "PioneerPlaque"
	var p_box = BoxMesh.new()
	p_box.size = Vector3(0.23, 0.15, 0.005)
	p_box.material = mat_plaque
	plaque.mesh = p_box
	plaque.position = Vector3(0.28, 0.28, -0.15)
	_attach_component_info(plaque, "The Pioneer Plaque", "Gold-anodized aluminum plate designed by Carl Sagan depicting nude human figures, hydrogen spin-flip, and 14 pulsar navigation map.", "Dimensions: 229x152 mm | Material: 6061-T6 Gold-anodized aluminum")
	root.add_child(plaque)

	return root

# 11. Kepler Space Telescope (Earth-trailing Heliocentric Orbit)
# Total height: 4.70m, Diameter: 2.70m, Mass: 1,052.4 kg
static func build_kepler_telescope() -> Node3D:
	var root = Node3D.new()
	root.name = "KeplerSpaceTelescope"
	_attach_component_info(root, "Kepler Space Telescope", "NASA's premier exoplanet-hunting space observatory; discovered >2,600 alien worlds (2009–2018).", "Height: 4.7 m | Aperture: 0.95 m | Mirror: 1.4 m | Orbit: Earth-trailing heliocentric")

	var mat_alu = get_material("aluminum_anodized", 0.0)
	var mat_solar = get_material("solar_cell_silicon", 0.0)
	var mat_gold = get_material("gold_kapton_mli", 0.0)
	var mat_lens = get_material("optical_glass", 0.0)
	var mat_white = get_material("white_ceramic_paint", 0.0)

	# Hexagonal Spacecraft Service Bus (Bottom)
	var bus = MeshInstance3D.new()
	bus.name = "HexagonalServiceBus"
	var b_cyl = CylinderMesh.new()
	b_cyl.radial_segments = 6
	b_cyl.top_radius = 1.35
	b_cyl.bottom_radius = 1.35
	b_cyl.height = 0.95
	b_cyl.material = mat_gold
	bus.mesh = b_cyl
	bus.position = Vector3(0.0, 0.48, 0.0)
	_attach_component_info(bus, "Spacecraft Service Bus", "Houses reaction wheels for milli-arcsecond precision pointing, avionics, hydrazine thrusters, and star trackers.", "Reaction wheels: 4 (2 failed during mission) | Pointing precision: <0.009 arcsec")
	root.add_child(bus)

	# Cylindrical Photometer Telescope Barrel (0.95m aperture Schmidt telescope)
	var barrel = MeshInstance3D.new()
	barrel.name = "SchmidtPhotometerTelescope"
	var t_cyl = CylinderMesh.new()
	t_cyl.top_radius = 0.70
	t_cyl.bottom_radius = 0.70
	t_cyl.height = 3.20
	t_cyl.material = mat_white
	barrel.mesh = t_cyl
	barrel.position = Vector3(0.0, 2.55, 0.0)
	_attach_component_info(barrel, "Schmidt Photometer Telescope", "0.95m aperture Schmidt optical photometer monitoring transit brightness of 150,000 stars simultaneously.", "Aperture: 0.95 m (3.1 ft) | Primary mirror: 1.4 m | Focal plane: 42 CCDs (95 MP)")
	root.add_child(barrel)

	# Optical Corrector Plate Aperture (Beveled Sunshade Top)
	var corrector = MeshInstance3D.new()
	corrector.name = "SchmidtCorrectorAperture"
	var c_cyl = CylinderMesh.new()
	c_cyl.top_radius = 0.48
	c_cyl.bottom_radius = 0.48
	c_cyl.height = 0.05
	c_cyl.material = mat_lens
	corrector.mesh = c_cyl
	corrector.position = Vector3(0.0, 4.15, 0.0)
	corrector.rotation_degrees = Vector3(18, 0, 0)
	_attach_component_info(corrector, "Fused Silica Corrector Plate", "0.95m aspheric corrector plate eliminating spherical aberration across a 115 deg² field of view.", "Material: Fused silica | Diameter: 0.95 m")
	root.add_child(corrector)

	# Curved Solar Array on Sunward Side of Barrel
	var solar = MeshInstance3D.new()
	solar.name = "CurvedSunshadeSolarArray"
	var s_cyl = CylinderMesh.new()
	s_cyl.top_radius = 0.75
	s_cyl.bottom_radius = 0.75
	s_cyl.height = 2.80
	s_cyl.material = mat_solar
	solar.mesh = s_cyl
	solar.position = Vector3(0.0, 2.50, -0.15)
	_attach_component_info(solar, "Sunshade Solar Array", "10.2 m² curved solar array generating 1,100W while serving as sunshield protecting the cold telescope interior.", "Area: 10.2 m² | Output: 1,100 W | Protects focal plane at -85°C")
	root.add_child(solar)

	# High-Gain Telemetry Dish
	var hga = MeshInstance3D.new()
	hga.name = "HighGainTelemetryDish"
	var d_cyl = CylinderMesh.new()
	d_cyl.top_radius = 0.42
	d_cyl.bottom_radius = 0.08
	d_cyl.height = 0.12
	d_cyl.material = mat_alu
	hga.mesh = d_cyl
	hga.position = Vector3(1.25, 0.85, 0.0)
	hga.rotation_degrees = Vector3(0, 0, -45)
	_attach_component_info(hga, "High-Gain Ka-Band Antenna", "Steerable parabolic antenna transmitting gigabits of stellar lightcurve photometry to DSN.", "Frequency: Ka-band | Rate: up to 4.3 Mbps")
	root.add_child(hga)

	return root
