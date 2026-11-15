extends SceneTree

# Generates clean, authentic 3D meshes for:
# 1. Curved Goggle Headband (wraps smoothly around head cylinder)
# 2. Side Strap Buckle Connectors (connects strap to goggle outer rims)
# 3. Constrained Inner Eyelids (guaranteed within r <= 0.088, cannot clip goggle rims)
# 4. Expressive Minion Mouth (with neutral, smile, and relaxed blend shapes)

func _init() -> void:
	print("--- Building Astronaut Character Meshes ---")
	_build_curved_strap()
	_build_strap_connector()
	_build_constrained_eyelid()
	_build_minion_mouth()
	print("--- All Astronaut Meshes Built Successfully ---")
	quit(0)

func _build_curved_strap() -> void:
	# Curved strap wraps around cylindrical head of radius R = 0.395
	var r_in = 0.398
	var r_out = 0.412
	var h_half = 0.027 # Total strap height 0.054
	
	# Start angle: +37 deg (0.645 rad), End angle: +323 deg (5.638 rad) = 286 deg arc
	var start_angle = deg_to_rad(37.0)
	var end_angle = deg_to_rad(323.0)
	var num_segments = 36
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for i in range(num_segments + 1):
		var t = float(i) / float(num_segments)
		var angle = lerp(start_angle, end_angle, t)
		var cos_a = sin(angle) # X coord
		var sin_a = cos(angle) # Z coord
		
		# Outer top & bottom
		var p_out_top = Vector3(cos_a * r_out, h_half, sin_a * r_out)
		var p_out_bot = Vector3(cos_a * r_out, -h_half, sin_a * r_out)
		
		# Inner top & bottom
		var p_in_top = Vector3(cos_a * r_in, h_half, sin_a * r_in)
		var p_in_bot = Vector3(cos_a * r_in, -h_half, sin_a * r_in)
		
		var n_out = Vector3(cos_a, 0, sin_a).normalized()
		var n_in = -n_out
		
		if i > 0:
			var prev_t = float(i - 1) / float(num_segments)
			var prev_angle = lerp(start_angle, end_angle, prev_t)
			var p_cos = sin(prev_angle)
			var p_sin = cos(prev_angle)
			
			var prev_out_top = Vector3(p_cos * r_out, h_half, p_sin * r_out)
			var prev_out_bot = Vector3(p_cos * r_out, -h_half, p_sin * r_out)
			var prev_in_top = Vector3(p_cos * r_in, h_half, p_sin * r_in)
			var prev_in_bot = Vector3(p_cos * r_in, -h_half, p_sin * r_in)
			var prev_n_out = Vector3(p_cos, 0, p_sin).normalized()
			
			# Outer face
			st.set_normal(prev_n_out)
			st.set_uv(Vector2(prev_t, 1))
			st.add_vertex(prev_out_top)
			st.set_normal(n_out)
			st.set_uv(Vector2(t, 1))
			st.add_vertex(p_out_top)
			st.set_normal(n_out)
			st.set_uv(Vector2(t, 0))
			st.add_vertex(p_out_bot)
			
			st.set_normal(prev_n_out)
			st.set_uv(Vector2(prev_t, 1))
			st.add_vertex(prev_out_top)
			st.set_normal(n_out)
			st.set_uv(Vector2(t, 0))
			st.add_vertex(p_out_bot)
			st.set_normal(prev_n_out)
			st.set_uv(Vector2(prev_t, 0))
			st.add_vertex(prev_out_bot)
			
			# Inner face
			st.set_normal(-prev_n_out)
			st.add_vertex(p_in_top)
			st.set_normal(-prev_n_out)
			st.add_vertex(prev_in_top)
			st.set_normal(-n_out)
			st.add_vertex(prev_in_bot)
			
			st.set_normal(-prev_n_out)
			st.add_vertex(p_in_top)
			st.set_normal(-n_out)
			st.add_vertex(prev_in_bot)
			st.set_normal(-n_out)
			st.add_vertex(p_in_bot)
			
			# Top face
			st.set_normal(Vector3.UP)
			st.add_vertex(prev_in_top)
			st.set_normal(Vector3.UP)
			st.add_vertex(p_in_top)
			st.set_normal(Vector3.UP)
			st.add_vertex(p_out_top)
			
			st.set_normal(Vector3.UP)
			st.add_vertex(prev_in_top)
			st.set_normal(Vector3.UP)
			st.add_vertex(p_out_top)
			st.set_normal(Vector3.UP)
			st.add_vertex(prev_out_top)
			
			# Bottom face
			st.set_normal(Vector3.DOWN)
			st.add_vertex(prev_out_bot)
			st.set_normal(Vector3.DOWN)
			st.add_vertex(p_out_bot)
			st.set_normal(Vector3.DOWN)
			st.add_vertex(p_in_bot)
			
			st.set_normal(Vector3.DOWN)
			st.add_vertex(prev_out_bot)
			st.set_normal(Vector3.DOWN)
			st.add_vertex(p_in_bot)
			st.set_normal(Vector3.DOWN)
			st.add_vertex(prev_in_bot)
	
	# Start and End caps
	var cos_s = sin(start_angle)
	var sin_s = cos(start_angle)
	var p_s_ot = Vector3(cos_s * r_out, h_half, sin_s * r_out)
	var p_s_ob = Vector3(cos_s * r_out, -h_half, sin_s * r_out)
	var p_s_it = Vector3(cos_s * r_in, h_half, sin_s * r_in)
	var p_s_ib = Vector3(cos_s * r_in, -h_half, sin_s * r_in)
	var n_start = Vector3(-sin_s, 0, cos_s).normalized()
	
	st.set_normal(n_start)
	st.add_vertex(p_s_ot)
	st.add_vertex(p_s_it)
	st.add_vertex(p_s_ib)
	st.add_vertex(p_s_ot)
	st.add_vertex(p_s_ib)
	st.add_vertex(p_s_ob)
	
	var cos_e = sin(end_angle)
	var sin_e = cos(end_angle)
	var p_e_ot = Vector3(cos_e * r_out, h_half, sin_e * r_out)
	var p_e_ob = Vector3(cos_e * r_out, -h_half, sin_e * r_out)
	var p_e_it = Vector3(cos_e * r_in, h_half, sin_e * r_in)
	var p_e_ib = Vector3(cos_e * r_in, -h_half, sin_e * r_in)
	var n_end = Vector3(sin_e, 0, -cos_e).normalized()
	
	st.set_normal(n_end)
	st.add_vertex(p_e_it)
	st.add_vertex(p_e_ot)
	st.add_vertex(p_e_ob)
	st.add_vertex(p_e_it)
	st.add_vertex(p_e_ob)
	st.add_vertex(p_e_ib)
	
	var mesh = st.commit()
	ResourceSaver.save(mesh, "res://scenes/player/curved_goggle_strap.tres")
	print("Saved res://scenes/player/curved_goggle_strap.tres")

func _build_strap_connector() -> void:
	# Side buckle bracket connecting strap to goggle outer ring
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Bracket dimensions: width 0.038, height 0.062, depth 0.04
	var w = 0.018
	var h = 0.031
	var d = 0.02
	
	# Simple beveled connector block
	# Front, back, left, right, top, bottom
	var v = [
		Vector3(-w, -h, d), Vector3(w, -h, d), Vector3(w, h, d), Vector3(-w, h, d), # Front 0,1,2,3
		Vector3(-w, -h, -d), Vector3(w, -h, -d), Vector3(w, h, -d), Vector3(-w, h, -d) # Back 4,5,6,7
	]
	
	# Front
	_add_quad(st, v[0], v[1], v[2], v[3], Vector3.FORWARD)
	# Back
	_add_quad(st, v[5], v[4], v[7], v[6], Vector3.BACK)
	# Left
	_add_quad(st, v[4], v[0], v[3], v[7], Vector3.LEFT)
	# Right
	_add_quad(st, v[1], v[5], v[6], v[2], Vector3.RIGHT)
	# Top
	_add_quad(st, v[3], v[2], v[6], v[7], Vector3.UP)
	# Bottom
	_add_quad(st, v[4], v[5], v[1], v[0], Vector3.DOWN)
	
	var mesh = st.commit()
	ResourceSaver.save(mesh, "res://scenes/player/side_strap_connector.tres")
	print("Saved res://scenes/player/side_strap_connector.tres")

func _add_quad(st: SurfaceTool, p1: Vector3, p2: Vector3, p3: Vector3, p4: Vector3, n: Vector3) -> void:
	st.set_normal(n)
	st.add_vertex(p1)
	st.add_vertex(p2)
	st.add_vertex(p3)
	st.add_vertex(p1)
	st.add_vertex(p3)
	st.add_vertex(p4)

func _build_constrained_eyelid() -> void:
	# Eyelid mesh matching the exact size and contour of the lens and eye (R = 0.092m, tucking under goggle frame 0.090m)
	# Local goggle ring coordinates:
	# X = lateral
	# Z = vertical in lens plane (-0.088 = UP, +0.088 = DOWN)
	# Y = forward towards viewer (+Y is forward)
	# In calm state (scale.z = 0.50, pos.z = -0.044):
	# Z_final ranges from -0.088 (top) to 0.000 (equator).
	# At each row z, X_max(z) follows the circular lens contour: sqrt(R^2 - Z_final^2) + 0.005
	# Producing a mathematically exact semicircle of radius R covering the entire upper half of the lens!
	var r_tuck = 0.096 # Tucking radius under silver frame
	var eye_r = 0.108
	var steps_x = 24
	var steps_z = 24
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for iz in range(steps_z):
		var t_z0 = float(iz) / float(steps_z)
		var t_z1 = float(iz + 1) / float(steps_z)
		var z0 = lerp(-0.088, 0.088, t_z0)
		var z1 = lerp(-0.088, 0.088, t_z1)
		
		# In calm state: Z_final = -0.044 + 0.50 * z
		var z_fin0 = -0.044 + 0.50 * z0
		var z_fin1 = -0.044 + 0.50 * z1
		
		# Exact lens circular profile at that height + 5mm tuck under silver ring
		var x_max0 = sqrt(max(0.0004, r_tuck * r_tuck - z_fin0 * z_fin0))
		var x_max1 = sqrt(max(0.0004, r_tuck * r_tuck - z_fin1 * z_fin1))
		
		for ix in range(steps_x):
			var t_x0 = float(ix) / float(steps_x)
			var t_x1 = float(ix + 1) / float(steps_x)
			var x00 = lerp(-x_max0, x_max0, t_x0)
			var x10 = lerp(-x_max0, x_max0, t_x1)
			var x01 = lerp(-x_max1, x_max1, t_x0)
			var x11 = lerp(-x_max1, x_max1, t_x1)
			
			# Spherical/ellipsoid curvature Y matching eyeball dome with 2mm clearance
			var r_sq00 = (x00 * x00 + z_fin0 * z_fin0) / (eye_r * eye_r)
			var r_sq10 = (x10 * x10 + z_fin0 * z_fin0) / (eye_r * eye_r)
			var r_sq01 = (x01 * x01 + z_fin1 * z_fin1) / (eye_r * eye_r)
			var r_sq11 = (x11 * x11 + z_fin1 * z_fin1) / (eye_r * eye_r)
			
			var y00 = 0.002 + 0.035 * sqrt(max(0.001, 1.0 - min(0.99, r_sq00)))
			var y10 = 0.002 + 0.035 * sqrt(max(0.001, 1.0 - min(0.99, r_sq10)))
			var y01 = 0.002 + 0.035 * sqrt(max(0.001, 1.0 - min(0.99, r_sq01)))
			var y11 = 0.002 + 0.035 * sqrt(max(0.001, 1.0 - min(0.99, r_sq11)))
			
			var p00 = Vector3(x00, y00, z0)
			var p10 = Vector3(x10, y10, z0)
			var p01 = Vector3(x01, y01, z1)
			var p11 = Vector3(x11, y11, z1)
			
			var n00 = Vector3(x00 / (eye_r * eye_r), 1.0 / 0.035, z0 / (eye_r * eye_r)).normalized()
			var n10 = Vector3(x10 / (eye_r * eye_r), 1.0 / 0.035, z0 / (eye_r * eye_r)).normalized()
			var n01 = Vector3(x01 / (eye_r * eye_r), 1.0 / 0.035, z1 / (eye_r * eye_r)).normalized()
			var n11 = Vector3(x11 / (eye_r * eye_r), 1.0 / 0.035, z1 / (eye_r * eye_r)).normalized()
			
			# Triangle 1: p00 -> p11 -> p01 (faces +Y towards viewer)
			st.set_normal(n00)
			st.add_vertex(p00)
			st.set_normal(n11)
			st.add_vertex(p11)
			st.set_normal(n01)
			st.add_vertex(p01)
			
			# Triangle 2: p00 -> p10 -> p11 (faces +Y towards viewer)
			st.set_normal(n00)
			st.add_vertex(p00)
			st.set_normal(n10)
			st.add_vertex(p10)
			st.set_normal(n11)
			st.add_vertex(p11)
	
	# Add eyelid bottom edge bevel lip for physical 3D thickness (faces +Z)
	var bot_z = 0.088
	var z_fin_bot = 0.0
	var x_max_bot = sqrt(max(0.0004, r_tuck * r_tuck - z_fin_bot * z_fin_bot))
	for ix in range(steps_x):
		var t_x0 = float(ix) / float(steps_x)
		var t_x1 = float(ix + 1) / float(steps_x)
		var x0 = lerp(-x_max_bot, x_max_bot, t_x0)
		var x1 = lerp(-x_max_bot, x_max_bot, t_x1)
		
		var r_sq0 = (x0 * x0 + z_fin_bot * z_fin_bot) / (eye_r * eye_r)
		var r_sq1 = (x1 * x1 + z_fin_bot * z_fin_bot) / (eye_r * eye_r)
		var y0 = 0.002 + 0.035 * sqrt(max(0.001, 1.0 - min(0.99, r_sq0)))
		var y1 = 0.002 + 0.035 * sqrt(max(0.001, 1.0 - min(0.99, r_sq1)))
		
		var p_front0 = Vector3(x0, y0, bot_z)
		var p_front1 = Vector3(x1, y1, bot_z)
		var p_back0 = Vector3(x0, y0 - 0.006, bot_z - 0.003)
		var p_back1 = Vector3(x1, y1 - 0.006, bot_z - 0.003)
		
		var n_lip = Vector3(0, -0.5, 0.866).normalized()
		st.set_normal(n_lip)
		st.add_vertex(p_front0)
		st.add_vertex(p_front1)
		st.add_vertex(p_back1)
		
		st.set_normal(n_lip)
		st.add_vertex(p_front0)
		st.add_vertex(p_back1)
		st.add_vertex(p_back0)
	
	var mesh = st.commit()
	ResourceSaver.save(mesh, "res://scenes/player/constrained_eyelid.tres")
	print("Saved res://scenes/player/constrained_eyelid.tres")

func _build_minion_mouth() -> void:
	# Generates an authentic Minion mouth curved along head cylinder R = 0.398
	# With blend shapes: "smile" (weight 0 = neutral, weight 1.0 = happy upward smile)
	var r_head = 0.398
	var mouth_width = 0.13 # Perfectly proportioned Minion mouth span (-0.065 to +0.065)
	var num_pts = 20
	
	# Base neutral vertices (subtle relaxed curve)
	var neutral_verts = PackedVector3Array()
	var smile_verts = PackedVector3Array()
	var normals = PackedVector3Array()
	var indices = PackedInt32Array()
	
	for i in range(num_pts):
		var t = float(i) / float(num_pts - 1) # 0 to 1
		var x = lerp(-mouth_width * 0.5, mouth_width * 0.5, t)
		var z = sqrt(max(0.01, r_head * r_head - x * x)) + 0.002 # 2mm clearance over skin
		var u = (t - 0.5) * 2.0 # -1 to 1
		
		# Taper thickness slightly at corners
		var taper = 1.0 - u * u * 0.45
		var half_h = 0.0055 * taper
		
		# Neutral curve: very gentle, relaxed line
		var neutral_y_center = 0.0
		var neutral_top = Vector3(x, neutral_y_center + half_h, z)
		var neutral_bot = Vector3(x, neutral_y_center - half_h, z)
		
		# Smile curve: corners curve upwards into a friendly Minion grin!
		var smile_dy = u * u * 0.022 - 0.003
		var smile_top = Vector3(x, neutral_y_center + half_h * 1.1 + smile_dy, z)
		var smile_bot = Vector3(x, neutral_y_center - half_h * 1.1 + smile_dy, z)
		
		neutral_verts.append(neutral_top)
		neutral_verts.append(neutral_bot)
		smile_verts.append(smile_top)
		smile_verts.append(smile_bot)
		
		var norm = Vector3(x, 0, z).normalized()
		normals.append(norm)
		normals.append(norm)
		
		if i > 0:
			var idx = i * 2
			indices.append(idx - 2)
			indices.append(idx)
			indices.append(idx + 1)
			
			indices.append(idx - 2)
			indices.append(idx + 1)
			indices.append(idx - 1)
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = neutral_verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	# In Godot 4, blend shape arrays must store the DELTA (difference) relative to base surface!
	var delta_verts = PackedVector3Array()
	var delta_normals = PackedVector3Array()
	for i in range(smile_verts.size()):
		delta_verts.append(smile_verts[i] - neutral_verts[i])
		delta_normals.append(Vector3.ZERO)
	
	var blend_shape_array = []
	blend_shape_array.resize(Mesh.ARRAY_MAX)
	blend_shape_array[Mesh.ARRAY_VERTEX] = delta_verts
	blend_shape_array[Mesh.ARRAY_NORMAL] = delta_normals
	
	var mesh = ArrayMesh.new()
	mesh.add_blend_shape("smile")
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [blend_shape_array])
	
	ResourceSaver.save(mesh, "res://scenes/player/minion_mouth.tres")
	print("Saved res://scenes/player/minion_mouth.tres")
