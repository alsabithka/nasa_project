extends SceneTree

# Generates high-precision aerospace telemetry UI textures
# Color Palette:
# - Background: Near-black (#05090D) -> Color(0.0196, 0.0353, 0.0510)
# - Primary accent: Electric cyan (#00E5FF) -> Color(0.0, 0.898, 1.0)
# - Secondary accent: Turquoise (#00BFA5) -> Color(0.0, 0.749, 0.647)
# - Warning: Amber/orange (#FF9D32) -> Color(1.0, 0.616, 0.196)
# - Critical: Muted red (#FF4545) -> Color(1.0, 0.271, 0.271)
# - Positive status: Green (#39E58C) -> Color(0.224, 0.898, 0.549)
# - Primary text: Cool white (#E5F2F5) -> Color(0.898, 0.949, 0.961)
# - Secondary text: Muted blue-grey (#77909D) -> Color(0.467, 0.565, 0.616)

const UI_DIR = "res://textures/ui/"

func _init() -> void:
	print("--- Generating Aerospace Telemetry UI Assets ---")
	
	# 1. Primary Glass Panel (Electric Cyan with Turquoise accents)
	_create_aerospace_panel("sci_fi_glass_panel.png", 96, 96,
		Color(0.0196, 0.0353, 0.0510, 0.86), # Near-black glass
		Color(0.0, 0.898, 1.0, 0.95),        # Electric cyan border
		Color(0.0, 0.749, 0.647, 0.95),      # Turquoise corner brackets
		Color(0.0, 0.898, 1.0, 0.12),        # Cyan micro-grid lines
		16
	)
	
	# 2. Warning / Discovery Glass Panel (Amber with Cyan accents)
	_create_aerospace_panel("sci_fi_orange_panel.png", 96, 96,
		Color(0.035, 0.025, 0.015, 0.88),   # Near-black warm glass
		Color(1.0, 0.616, 0.196, 0.95),      # Amber border
		Color(0.0, 0.898, 1.0, 0.95),        # Cyan corner brackets
		Color(1.0, 0.616, 0.196, 0.12),      # Amber micro-grid lines
		16
	)
	
	# 3. Critical / Alert Glass Panel (Muted Red)
	_create_aerospace_panel("aerospace_critical_panel.png", 96, 96,
		Color(0.04, 0.015, 0.015, 0.88),
		Color(1.0, 0.271, 0.271, 0.95),
		Color(1.0, 0.616, 0.196, 0.95),
		Color(1.0, 0.271, 0.271, 0.12),
		16
	)
	
	# 4. Buttons (Normal, Hover, Pressed, Disabled)
	_create_aerospace_button("sci_fi_btn_normal.png", 64, 64,
		Color(0.0196, 0.0353, 0.0510, 0.80), # Near-black glass
		Color(0.0, 0.898, 1.0, 0.75),        # Cyan border
		Color(0.0, 0.749, 0.647, 0.90),      # Turquoise corner brackets
		Color(0.0, 0.898, 1.0, 0.08)
	)
	
	_create_aerospace_button("sci_fi_btn_hover.png", 64, 64,
		Color(0.025, 0.07, 0.10, 0.92),      # Brighter cyan glass
		Color(0.0, 0.95, 1.0, 1.0),          # Pure cyan
		Color(0.0, 0.898, 1.0, 1.0),         # Cyan corners
		Color(0.0, 0.898, 1.0, 0.22)
	)
	
	_create_aerospace_button("sci_fi_btn_pressed.png", 64, 64,
		Color(0.06, 0.04, 0.01, 0.95),       # Amber glass flash
		Color(1.0, 0.616, 0.196, 1.0),       # Amber border
		Color(1.0, 0.75, 0.3, 1.0),          # Amber bright corners
		Color(1.0, 0.616, 0.196, 0.25)
	)
	
	_create_aerospace_button("aerospace_btn_disabled.png", 64, 64,
		Color(0.015, 0.02, 0.03, 0.60),
		Color(0.467, 0.565, 0.616, 0.40),    # Muted blue-grey border
		Color(0.467, 0.565, 0.616, 0.50),
		Color(0.0, 0.0, 0.0, 0.0)
	)
	
	# 5. Technical Grid Background for Menu and Modals (256x256 seamless)
	_create_aerospace_grid_bg("aerospace_grid_bg.png", 256, 256)
	
	# 6. Slider Grabber Diamond (16x16)
	_create_slider_grabber("aerospace_slider_grabber.png", 16, 16)
	
	print("--- All Aerospace UI Assets Generated Successfully ---")
	quit(0)

# Creates an engineered aerospace panel texture with chamfered notches, thin vector border, and technical corner brackets
func _create_aerospace_panel(file_name: String, w: int, h: int, bg_col: Color, border_col: Color, bracket_col: Color, grid_col: Color, bracket_len: int) -> void:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var border_thick = 1
	var corner_cut = 7 # 45-degree chamfered corner
	
	for y in range(h):
		for x in range(w):
			# 45-degree corner chamfer
			if (x < corner_cut and y < corner_cut - x) or \
			   (x >= w - corner_cut and y < corner_cut - (w - 1 - x)) or \
			   (x < corner_cut and y >= h - corner_cut + x) or \
			   (x >= w - corner_cut and y >= h - corner_cut + (w - 1 - x)):
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			
			var is_edge = (x < border_thick or x >= w - border_thick or y < border_thick or y >= h - border_thick)
			var is_chamfer_edge = (x < corner_cut and y == corner_cut - x) or \
								  (x >= w - corner_cut and y == corner_cut - (w - 1 - x)) or \
								  (x < corner_cut and y == h - corner_cut + x) or \
								  (x >= w - corner_cut and y == h - corner_cut + (w - 1 - x))
			
			# Technical corner bracket: thicker L-brackets at each corner
			var is_bracket_x = (x < bracket_len or x >= w - bracket_len)
			var is_bracket_y = (y < bracket_len or y >= h - bracket_len)
			var is_bracket = (is_bracket_x and (y < border_thick + 2 or y >= h - border_thick - 2)) or \
							 (is_bracket_y and (x < border_thick + 2 or x >= w - border_thick - 2))
			
			if is_chamfer_edge:
				img.set_pixel(x, y, bracket_col)
			elif is_bracket:
				img.set_pixel(x, y, bracket_col)
			elif is_edge:
				img.set_pixel(x, y, border_col)
			else:
				# Background glass with fine technical grid pattern (16px grid)
				var col = bg_col
				if (x % 16 == 0 or y % 16 == 0):
					col = col.blend(grid_col)
				# Center dot marker at intersections
				if (x % 16 == 0 and y % 16 == 0):
					col = col.blend(Color(grid_col.r, grid_col.g, grid_col.b, 0.35))
				img.set_pixel(x, y, col)
	
	img.save_png(UI_DIR + file_name)
	print("Saved ", file_name)

# Creates engineered buttons with chamfered corners and technical accent lines
func _create_aerospace_button(file_name: String, w: int, h: int, bg_col: Color, border_col: Color, bracket_col: Color, fill_glow: Color) -> void:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var thick = 1
	var corner_len = 8
	var cut = 5
	
	for y in range(h):
		for x in range(w):
			# Chamfer corners
			if (x < cut and y < cut - x) or \
			   (x >= w - cut and y < cut - (w - 1 - x)) or \
			   (x < cut and y >= h - cut + x) or \
			   (x >= w - cut and y >= h - cut + (w - 1 - x)):
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			
			var is_edge = (x < thick or x >= w - thick or y < thick or y >= h - thick)
			var is_chamfer_edge = (x < cut and y == cut - x) or \
								  (x >= w - cut and y == cut - (w - 1 - x)) or \
								  (x < cut and y == h - cut + x) or \
								  (x >= w - cut and y == h - cut + (w - 1 - x))
			
			var is_bracket = (x < corner_len and (y < thick + 2 or y >= h - thick - 2)) or \
							 (x >= w - corner_len and (y < thick + 2 or y >= h - thick - 2)) or \
							 (y < corner_len and (x < thick + 2 or x >= w - thick - 2)) or \
							 (y >= h - corner_len and (x < thick + 2 or x >= w - thick - 2))
			
			if is_chamfer_edge or is_bracket:
				img.set_pixel(x, y, bracket_col)
			elif is_edge:
				img.set_pixel(x, y, border_col)
			else:
				var col = bg_col.blend(fill_glow)
				# Subtle horizontal scanlines
				if y % 4 == 0:
					col.a = minf(col.a + 0.05, 1.0)
				img.set_pixel(x, y, col)
	
	img.save_png(UI_DIR + file_name)
	print("Saved ", file_name)

# Creates seamless 256x256 dark space background with technical micro-grid and coordinate ticks
func _create_aerospace_grid_bg(file_name: String, w: int, h: int) -> void:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var base_col = Color(0.0196, 0.0353, 0.0510, 1.0) # Near-black #05090D
	var subgrid_col = Color(0.0, 0.898, 1.0, 0.04)   # Subtle 16px grid
	var maingrid_col = Color(0.0, 0.898, 1.0, 0.09)  # 64px main grid
	var dot_col = Color(0.0, 0.898, 1.0, 0.25)       # Coordinate intersection dot
	
	for y in range(h):
		for x in range(w):
			var col = base_col
			if x % 64 == 0 or y % 64 == 0:
				col = col.blend(maingrid_col)
			elif x % 16 == 0 or y % 16 == 0:
				col = col.blend(subgrid_col)
			
			if (x % 64 == 0 and y % 64 == 0):
				col = col.blend(dot_col)
			
			img.set_pixel(x, y, col)
	
	img.save_png(UI_DIR + file_name)
	print("Saved ", file_name)

# Creates 16x16 technical diamond grabber for sliders
func _create_slider_grabber(file_name: String, w: int, h: int) -> void:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var cx = float(w) * 0.5 - 0.5
	var cy = float(h) * 0.5 - 0.5
	var r = float(w) * 0.45
	
	for y in range(h):
		for x in range(w):
			var m_dist = abs(float(x) - cx) + abs(float(y) - cy)
			if m_dist <= r:
				if m_dist > r - 1.2:
					img.set_pixel(x, y, Color(0.0, 0.898, 1.0, 1.0)) # Cyan border
				else:
					img.set_pixel(x, y, Color(0.0, 0.749, 0.647, 0.95)) # Turquoise fill
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	
	img.save_png(UI_DIR + file_name)
	print("Saved ", file_name)
