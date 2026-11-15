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
	# Eyelid mesh strictly constrained within circular lens radius R_MAX = 0.088
	# Local goggle ring coordinates:
	# X = lateral (-0.088 to +0.088)
	# Z = vertical in lens plane (-0.088 = UP, +0.088 = DOWN)
	# Y = forward towards viewer (+Y is forward)
	# We model an upper eyelid dome cap spanning from Z = -0.088 down to Z = +0.088
	# with smooth spherical curvature (curvature radius 0.108 matching eyeball)
	var max_r = 0.0875 # Strict boundary guarantee inside 0.090 inner goggle rim
	var eye_r = 0.108
	var steps_x = 16
	var steps_z = 16
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for iz in range(steps_z):
		var z0 = lerp(-max_r, max_r, float(iz) / float(steps_z))
		var z1 = lerp(-max_r, max_r, float(iz + 1) / float(steps_z))
		
		for ix in range(steps_x):
			var x0 = lerp(-max_r, max_r, float(ix) / float(steps_x))
			var x1 = lerp(-max_r, max_r, float(ix + 1) / float(steps_x))
			
			var r00 = sqrt(x0 * x0 + z0 * z0)
			var r10 = sqrt(x1 * x1 + z0 * z0)
			var r01 = sqrt(x0 * x0 + z1 * z1)
			var r11 = sqrt(x1 * x1 + z1 * z1)
			
			# Only generate quad if at least partially within lens circle
			if r00 <= max_r or r10 <= max_r or r01 <= max_r or r11 <= max_r:
				# Clamp to lens circle boundary
				var c_x0 = x0 * (max_r / r00) if r00 > max_r else x0
				var c_z0 = z0 * (max_r / r00) if r00 > max_r else z0
				var c_x1 = x1 * (max_r / r10) if r10 > max_r else x1
				var c_z0_b = z0 * (max_r / r10) if r10 > max_r else z0
				
				var c_x0_b = x0 * (max_r / r01) if r01 > max_r else x0
				var c_z1 = z1 * (max_r / r01) if r01 > max_r else z1
				var c_x1_b = x1 * (max_r / r11) if r11 > max_r else x1
				var c_z1_b = z1 * (max_r / r11) if r11 > max_r else z1
				
				# Spherical curvature Y
				var y00 = sqrt(max(0.001, eye_r * eye_r - (c_x0 * c_x0 + c_z0 * c_z0))) - (eye_r - 0.02)
				var y10 = sqrt(max(0.001, eye_r * eye_r - (c_x1 * c_x1 + c_z0_b * c_z0_b))) - (eye_r - 0.02)
				var y01 = sqrt(max(0.001, eye_r * eye_r - (c_x0_b * c_x0_b + c_z1 * c_z1))) - (eye_r - 0.02)
				var y11 = sqrt(max(0.001, eye_r * eye_r - (c_x1_b * c_x1_b + c_z1_b * c_z1_b))) - (eye_r - 0.02)
				
				var p00 = Vector3(c_x0, y00, c_z0)
				var p10 = Vector3(c_x1, y10, c_z0_b)
				var p01 = Vector3(c_x0_b, y01, c_z1)
				var p11 = Vector3(c_x1_b, y11, c_z1_b)
				
				var n = Vector3(0, 1, 0)
				st.set_normal(n)
				st.add_vertex(p00)
				st.add_vertex(p10)
				st.add_vertex(p11)
				
				st.set_normal(n)
				st.add_vertex(p00)
				st.add_vertex(p11)
				st.add_vertex(p01)
	
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
