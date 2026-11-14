extends SceneTree

# Generates 9-Slice and Tactical Vector Textures for Futuristic Sci-Fi Holographic UI

const UI_DIR = "res://textures/ui/"

func _init() -> void:
	print("--- Generating Sci-Fi Holographic UI Assets ---")
	
	_create_9slice_panel("sci_fi_glass_panel.png", 96, 96, 
		Color(0.03, 0.06, 0.10, 0.72), # Dark transparent glass
		Color(0.0, 0.90, 1.0, 0.95),   # Neon Cyan border
		Color(1.0, 0.60, 0.08, 0.95),   # Neon Orange corner accents
		14
	)
	
	_create_9slice_panel("sci_fi_orange_panel.png", 96, 96,
		Color(0.05, 0.03, 0.02, 0.75), # Dark warm glass
		Color(1.0, 0.60, 0.08, 0.95),   # Neon Orange border
		Color(0.0, 0.90, 1.0, 0.95),   # Neon Cyan corner accents
		14
	)
	
	_create_9slice_button("sci_fi_btn_normal.png", 64, 64,
		Color(0.04, 0.08, 0.14, 0.70),
		Color(0.0, 0.75, 0.92, 0.75),
		Color(0.0, 0.92, 1.0, 0.90)
	)
	
	_create_9slice_button("sci_fi_btn_hover.png", 64, 64,
		Color(0.06, 0.14, 0.22, 0.88),
		Color(0.0, 1.0, 1.0, 1.0),
		Color(1.0, 0.65, 0.1, 1.0)
	)
	
	_create_9slice_button("sci_fi_btn_pressed.png", 64, 64,
		Color(0.16, 0.08, 0.02, 0.92),
		Color(1.0, 0.65, 0.1, 1.0),
		Color(0.0, 1.0, 1.0, 1.0)
	)
	
	_create_minimap_dial("sci_fi_minimap_dial.png", 160)
	
	print("--- All Sci-Fi UI Textures Generated Successfully ---")
	quit(0)

# Creates a 9-slice panel texture with transparent glass center, neon vector border, and tactical corner brackets
func _create_9slice_panel(file_name: String, w: int, h: int, bg_col: Color, border_col: Color, accent_col: Color, bracket_len: int) -> void:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var border_thick = 2
	
	for y in range(h):
		for x in range(w):
			var is_edge = (x < border_thick or x >= w - border_thick or y < border_thick or y >= h - border_thick)
			var is_corner_x = (x < bracket_len or x >= w - bracket_len)
			var is_corner_y = (y < bracket_len or y >= h - bracket_len)
			var is_bracket = (is_corner_x and (y < border_thick + 2 or y >= h - border_thick - 2)) or \
							 (is_corner_y and (x < border_thick + 2 or x >= w - border_thick - 2))
			
			# Sci-Fi Chamfer 45-deg corner cuts
			var corner_cut = 6
			if (x < corner_cut and y < corner_cut - x) or \
			   (x >= w - corner_cut and y < corner_cut - (w - 1 - x)) or \
			   (x < corner_cut and y >= h - corner_cut + x) or \
			   (x >= w - corner_cut and y >= h - corner_cut + (w - 1 - x)):
				img.set_pixel(x, y, Color(0, 0, 0, 0)) # Transparent corner notch
				continue
			
			if is_bracket:
				img.set_pixel(x, y, accent_col)
			elif is_edge:
				img.set_pixel(x, y, border_col)
			else:
				# Subtle tech grid line pattern inside the transparent glass
				var col = bg_col
				if (x % 16 == 0 or y % 16 == 0):
					col.a = minf(col.a + 0.08, 1.0)
				img.set_pixel(x, y, col)
	
	img.save_png(UI_DIR + file_name)
	print("Saved ", file_name)

# Creates high-tech buttons with corner notches and vector lines
func _create_9slice_button(file_name: String, w: int, h: int, bg_col: Color, border_col: Color, corner_col: Color) -> void:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var thick = 2
	var corner_len = 8
	
	for y in range(h):
		for x in range(w):
			# Chamfer corners
			if (x < 4 and y < 4 - x) or \
			   (x >= w - 4 and y < 4 - (w - 1 - x)) or \
			   (x < 4 and y >= h - 4 + x) or \
			   (x >= w - 4 and y >= h - 4 + (w - 1 - x)):
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			
			var is_edge = (x < thick or x >= w - thick or y < thick or y >= h - thick)
			var is_corner = (x < corner_len and (y < thick + 1 or y >= h - thick - 1)) or \
							(x >= w - corner_len and (y < thick + 1 or y >= h - thick - 1)) or \
							(y < corner_len and (x < thick + 1 or x >= w - thick - 1)) or \
							(y >= h - corner_len and (x < thick + 1 or x >= w - thick - 1))
			
			if is_corner:
				img.set_pixel(x, y, corner_col)
			elif is_edge:
				img.set_pixel(x, y, border_col)
			else:
				img.set_pixel(x, y, bg_col)
	
	img.save_png(UI_DIR + file_name)
	print("Saved ", file_name)

# Creates circular tactical minimap dial texture
func _create_minimap_dial(file_name: String, size: int) -> void:
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center = Vector2(size * 0.5, size * 0.5)
	var radius = size * 0.47
	
	var cyan = Color(0.0, 0.90, 1.0, 0.95)
	var cyan_dim = Color(0.0, 0.70, 0.90, 0.35)
	var orange = Color(1.0, 0.60, 0.08, 0.95)
	var glass = Color(0.02, 0.05, 0.09, 0.75)
	
	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			var d = pos.distance_to(center)
			
			if d > radius + 2.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			
			# Outer tactical bezel ring
			if d >= radius - 2.0 and d <= radius:
				img.set_pixel(x, y, cyan)
				continue
			elif d > radius:
				# Subtle outer glow
				var a = (1.0 - (d - radius) / 2.0) * 0.4
				img.set_pixel(x, y, Color(cyan.r, cyan.g, cyan.b, a))
				continue
			
			# Inside the radar dial
			var col = glass
			
			# Range rings at 0.33, 0.66, 0.95
			var r1 = radius * 0.33
			var r2 = radius * 0.66
			if absf(d - r1) < 0.9 or absf(d - r2) < 0.9:
				col = cyan_dim
			
			# Crosshairs
			var dx = absf(pos.x - center.x)
			var dy = absf(pos.y - center.y)
			if (dx < 0.8 and d > 6.0) or (dy < 0.8 and d > 6.0):
				col = Color(cyan_dim.r, cyan_dim.g, cyan_dim.b, 0.45)
			
			# Azimuth tick marks every 30 degrees on outer edge
			if d >= radius - 6.0 and d <= radius - 2.0:
				var angle_deg = rad_to_deg(atan2(pos.y - center.y, pos.x - center.x))
				if angle_deg < 0: angle_deg += 360.0
				var mod30 = fmod(angle_deg, 30.0)
				if mod30 < 1.5 or mod30 > 28.5:
					col = orange if (fmod(angle_deg, 90.0) < 1.5 or fmod(angle_deg, 90.0) > 88.5) else cyan
			
			img.set_pixel(x, y, col)
	
	img.save_png(UI_DIR + file_name)
	print("Saved ", file_name)
