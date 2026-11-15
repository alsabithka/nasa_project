extends CanvasLayer

signal dig_finished
signal dig_cancelled

@export var artifact_id: String = ""

const COLS: int = 8
const ROWS: int = 5
const TILE_WIDTH: float = 72.0
const TILE_HEIGHT: float = 64.0
const GRID_GAP: float = 6.0

# Tile data: Array of Dictionary { layers, max_layers, is_rock, is_artifact, cleared, rect }
var tiles: Array = []
var combo_count: int = 0
var combo_timer: float = 0.0
var depth_progress: float = 0.0
var is_won: bool = false
var victory_timer: float = 0.0
var screen_shake: float = 0.0

# UI Controls
var panel_root: Control
var grid_canvas: Control
var depth_bar: ProgressBar
var combo_label: Label
var status_label: Label
var audio_player: AudioStreamPlayer

# Particles
var hit_sparks: Array = []

func _ready() -> void:
	layer = 15
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_setup_audio()
	_init_grid()
	_build_ui()

func _setup_audio() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "DigAudio"
	audio_player.bus = &"Master"
	audio_player.volume_db = -12.0
	add_child(audio_player)

func _play_sfx(type: String, pitch: float = 1.0) -> void:
	var sample_rate = 22050
	var duration = 0.10
	if type == "victory":
		duration = 0.60
	elif type == "power":
		duration = 0.25
	
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var wave = 0.0
		if type == "hit":
			var env = exp(-t * 32.0)
			wave = (sin(t * 120.0 * TAU) * 0.7 + (randf() * 2.0 - 1.0) * 0.3) * env
		elif type == "rock":
			var env = exp(-t * 26.0)
			wave = (sin(t * 880.0 * TAU) * 0.6 + sin(t * 1320.0 * TAU) * 0.3) * env
		elif type == "power":
			var env = exp(-t * 14.0)
			wave = (sin(t * 65.0 * TAU) * 0.8 + (randf() * 2.0 - 1.0) * 0.5) * env
		elif type == "victory":
			var env = clampf(1.0 - t / duration, 0.0, 1.0)
			# Aerospace chord (523Hz C5 + 659Hz E5 + 784Hz G5)
			wave = (sin(t * 523.25 * TAU) * 0.35 + sin(t * 659.25 * TAU) * 0.35 + sin(t * 783.99 * TAU) * 0.35) * env
		
		var sample_val = clampi(int(wave * 32767.0 * 0.5), -32767, 32767)
		var u16 = sample_val if sample_val >= 0 else (sample_val + 65536)
		data[i * 2] = u16 & 0xFF
		data[i * 2 + 1] = (u16 >> 8) & 0xFF
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	
	audio_player.stream = wav
	audio_player.pitch_scale = clampf(pitch, 0.8, 2.0)
	audio_player.play()

func _init_grid() -> void:
	tiles.clear()
	# Random generator seeded with artifact_id for stable replay
	var seed_val = hash(artifact_id) if not artifact_id.is_empty() else 12345
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_val
	
	for y in range(ROWS):
		for x in range(COLS):
			# Central silhouette: Columns 2..5, Rows 1..3
			var is_art = (x >= 2 and x <= 5 and y >= 1 and y <= 3)
			var is_rock = (rng.randf() < 0.20 and not is_art) # Rock tiles on perimeter
			var layers = 2
			if is_rock:
				layers = 3
			elif is_art:
				layers = rng.randi_range(2, 3)
			else:
				layers = rng.randi_range(1, 2)
			
			tiles.append({
				"x": x,
				"y": y,
				"layers": layers,
				"max_layers": layers,
				"is_rock": is_rock,
				"is_artifact": is_art,
				"cleared": false,
				"crack_anim": 0.0
			})

func _build_ui() -> void:
	panel_root = Control.new()
	panel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel_root)
	
	# Backdrop scrim
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.04, 0.07, 0.82)
	panel_root.add_child(bg)
	
	# Center HUD Frame
	var total_w = COLS * TILE_WIDTH + (COLS - 1) * GRID_GAP + 160.0
	var total_h = ROWS * TILE_HEIGHT + (ROWS - 1) * GRID_GAP + 180.0
	
	var frame = PanelContainer.new()
	frame.custom_minimum_size = Vector2(total_w, total_h)
	frame.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	frame.position = -frame.custom_minimum_size * 0.5
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.11, 0.95)
	sb.border_color = Color(0.0, 0.9, 1.0, 0.85) # Aerospace cyan
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	frame.add_theme_stylebox_override("panel", sb)
	panel_root.add_child(frame)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	frame.add_child(vbox)
	
	# Header
	var title = Label.new()
	title.text = "SUBSURFACE EXCAVATION PROTOCOL // REGOLITH DRILL GRID"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	status_label = Label.new()
	status_label.text = "Click tiles to drill regolith. Every 5 hits triggers POWER BURST. Esc to cancel."
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color(0.85, 0.92, 0.96))
	status_label.add_theme_font_size_override("font_size", 13)
	vbox.add_child(status_label)
	
	# Center Area: Depth meter + Grid
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 24)
	vbox.add_child(hbox)
	
	# Depth meter VBox
	var depth_box = VBoxContainer.new()
	depth_box.alignment = BoxContainer.ALIGNMENT_CENTER
	var depth_title = Label.new()
	depth_title.text = "DEPTH"
	depth_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	depth_title.add_theme_font_size_override("font_size", 11)
	depth_title.add_theme_color_override("font_color", Color(0.6, 0.75, 0.85))
	depth_box.add_child(depth_title)
	
	depth_bar = ProgressBar.new()
	depth_bar.fill_mode = ProgressBar.FILL_BOTTOM_TO_TOP
	depth_bar.custom_minimum_size = Vector2(24, ROWS * TILE_HEIGHT + (ROWS - 1) * GRID_GAP)
	depth_bar.min_value = 0.0
	depth_bar.max_value = 1.0
	depth_bar.value = 0.0
	depth_bar.show_percentage = true
	depth_box.add_child(depth_bar)
	hbox.add_child(depth_box)
	
	# Grid canvas
	grid_canvas = Control.new()
	grid_canvas.custom_minimum_size = Vector2(COLS * TILE_WIDTH + (COLS - 1) * GRID_GAP, ROWS * TILE_HEIGHT + (ROWS - 1) * GRID_GAP)
	grid_canvas.gui_input.connect(_on_grid_gui_input)
	grid_canvas.draw.connect(_on_grid_draw)
	hbox.add_child(grid_canvas)
	
	# Footer: Combo and Cancel hint
	var footer = HBoxContainer.new()
	vbox.add_child(footer)
	
	combo_label = Label.new()
	combo_label.text = "COMBO: 0x"
	combo_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.1))
	combo_label.add_theme_font_size_override("font_size", 15)
	footer.add_child(combo_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)
	
	var cancel_btn = Button.new()
	cancel_btn.text = "ESC - CANCEL"
	cancel_btn.pressed.connect(_cancel)
	footer.add_child(cancel_btn)

func _process(delta: float) -> void:
	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo_count = 0
			_update_combo_ui()
	
	# Update hit particle effects
	var alive_sparks = []
	for spark in hit_sparks:
		spark.life += delta
		spark.pos += spark.vel * delta
		if spark.life < spark.max_life:
			alive_sparks.append(spark)
	hit_sparks = alive_sparks
	
	if is_won:
		victory_timer += delta
		if victory_timer >= 1.2:
			dig_finished.emit()
			queue_free()
			return
	
	if screen_shake > 0.0:
		screen_shake = move_toward(screen_shake, 0.0, delta * 20.0)
		panel_root.position = Vector2(randf_range(-screen_shake, screen_shake), randf_range(-screen_shake, screen_shake))
	else:
		panel_root.position = Vector2.ZERO
	
	if grid_canvas:
		grid_canvas.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_cancel()

func _cancel() -> void:
	dig_cancelled.emit()
	queue_free()

func _on_grid_gui_input(event: InputEvent) -> void:
	if is_won:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var pos = event.position
		var tile_index = _get_tile_index_at(pos)
		if tile_index != -1:
			_hit_tile(tile_index)

func _get_tile_index_at(pos: Vector2) -> int:
	var total_w = TILE_WIDTH + GRID_GAP
	var total_h = TILE_HEIGHT + GRID_GAP
	var col = int(pos.x / total_w)
	var row = int(pos.y / total_h)
	if col >= 0 and col < COLS and row >= 0 and row < ROWS:
		var local_x = pos.x - col * total_w
		var local_y = pos.y - row * total_h
		if local_x <= TILE_WIDTH and local_y <= TILE_HEIGHT:
			return row * COLS + col
	return -1

func _hit_tile(idx: int) -> void:
	var tile = tiles[idx]
	if tile.cleared:
		return
	
	combo_count += 1
	combo_timer = 1.3
	_update_combo_ui()
	
	# Spawn dust sparks
	var tx = tile.x * (TILE_WIDTH + GRID_GAP) + TILE_WIDTH * 0.5
	var ty = tile.y * (TILE_HEIGHT + GRID_GAP) + TILE_HEIGHT * 0.5
	_spawn_particles(Vector2(tx, ty), 6)
	
	# Check power burst hit (every 5 combo hits)
	if combo_count % 5 == 0:
		_trigger_power_hit(tile.x, tile.y)
		return
	
	tile.layers -= 1
	tile.crack_anim = 1.0
	screen_shake = 3.0
	
	if tile.is_rock:
		_play_sfx("rock", 1.0 + combo_count * 0.03)
	else:
		_play_sfx("hit", 1.0 + combo_count * 0.03)
	
	if tile.layers <= 0:
		tile.cleared = true
		tile.layers = 0
	
	_check_win_condition()

func _trigger_power_hit(cx: int, cy: int) -> void:
	screen_shake = 9.0
	_play_sfx("power", 1.2)
	status_label.text = "★ POWER HIT! ADJACENT TILES CLEARED! ★"
	status_label.modulate = Color(1.0, 0.7, 0.1)
	
	# Clear clicked and all orthogonal/diagonal neighbors
	for dy in [-1, 0, 1]:
		for dx in [-1, 0, 1]:
			var nx = cx + dx
			var ny = cy + dy
			if nx >= 0 and nx < COLS and ny >= 0 and ny < ROWS:
				var n_idx = ny * COLS + nx
				var n_tile = tiles[n_idx]
				if not n_tile.cleared:
					n_tile.layers = max(0, n_tile.layers - 2)
					if n_tile.layers <= 0:
						n_tile.cleared = true
					var px = nx * (TILE_WIDTH + GRID_GAP) + TILE_WIDTH * 0.5
					var py = ny * (TILE_HEIGHT + GRID_GAP) + TILE_HEIGHT * 0.5
					_spawn_particles(Vector2(px, py), 4)
	
	_check_win_condition()

func _spawn_particles(origin: Vector2, count: int) -> void:
	for i in range(count):
		var ang = randf() * TAU
		var spd = randf_range(40.0, 160.0)
		hit_sparks.append({
			"pos": origin,
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"life": 0.0,
			"max_life": randf_range(0.25, 0.50),
			"color": Color(0.85, 0.88, 0.95, 1.0) if randf() < 0.6 else Color(0.0, 0.9, 1.0, 1.0)
		})

func _update_combo_ui() -> void:
	if combo_count > 0:
		combo_label.text = "COMBO: %dx (STREAK!)" % combo_count
		combo_label.modulate = Color(1.0, 0.65, 0.1).lerp(Color(1.0, 0.2, 0.1), clampf(combo_count / 15.0, 0.0, 1.0))
	else:
		combo_label.text = "COMBO: 0x"
		combo_label.modulate = Color(0.6, 0.65, 0.7)

func _check_win_condition() -> void:
	var total_artifact_tiles = 0
	var cleared_artifact_tiles = 0
	var total_tiles = tiles.size()
	var total_cleared = 0
	
	for tile in tiles:
		if tile.is_artifact:
			total_artifact_tiles += 1
			if tile.cleared:
				cleared_artifact_tiles += 1
		if tile.cleared:
			total_cleared += 1
	
	depth_progress = float(cleared_artifact_tiles) / float(total_artifact_tiles)
	depth_bar.value = depth_progress
	
	if cleared_artifact_tiles >= total_artifact_tiles and not is_won:
		is_won = true
		victory_timer = 0.0
		_play_sfx("victory", 1.0)
		status_label.text = "★ ARTIFACT FOUND! EXCAVATION SUCCESSFUL ★"
		status_label.modulate = Color(0.2, 0.95, 0.5)

func _on_grid_draw() -> void:
	# 1. Draw Artifact Silhouette underneath the grid
	var sil_x = 2 * (TILE_WIDTH + GRID_GAP)
	var sil_y = 1 * (TILE_HEIGHT + GRID_GAP)
	var sil_w = 4 * TILE_WIDTH + 3 * GRID_GAP
	var sil_h = 3 * TILE_HEIGHT + 2 * GRID_GAP
	var sil_rect = Rect2(sil_x, sil_y, sil_w, sil_h)
	
	# Glowing artifact silhouette representation
	var sil_col = Color(0.0, 0.8, 1.0, 0.35)
	if is_won:
		var flash = (sin(Time.get_ticks_msec() * 0.015) + 1.0) * 0.5
		sil_col = Color(0.2, 1.0, 0.6, 0.5 + flash * 0.4)
	grid_canvas.draw_rect(sil_rect, sil_col)
	grid_canvas.draw_rect(sil_rect, Color(0.0, 0.9, 1.0, 0.8), false, 2.0)
	
	# Draw artifact outline glyph / icon in silhouette center
	var center = sil_rect.get_center()
	grid_canvas.draw_circle(center, 28.0, Color(0.0, 0.9, 1.0, 0.25))
	grid_canvas.draw_arc(center, 34.0, 0.0, TAU, 32, Color(0.0, 0.9, 1.0, 0.8), 2.0)
	
	# 2. Draw Tiles
	for tile in tiles:
		var rx = tile.x * (TILE_WIDTH + GRID_GAP)
		var ry = tile.y * (TILE_HEIGHT + GRID_GAP)
		var rect = Rect2(rx, ry, TILE_WIDTH, TILE_HEIGHT)
		
		if tile.cleared:
			# Cleared tile: faint outline grid
			grid_canvas.draw_rect(rect, Color(0.0, 0.9, 1.0, 0.12), false, 1.0)
			continue
		
		# Solid dirt/rock tile based on remaining layers
		var fill_color: Color
		if tile.is_rock:
			fill_color = Color(0.36, 0.28, 0.22) # Dense boulder
		else:
			match tile.layers:
				3: fill_color = Color(0.18, 0.20, 0.24) # Deep compact regolith
				2: fill_color = Color(0.28, 0.31, 0.35) # Medium dirt
				_: fill_color = Color(0.42, 0.45, 0.49) # Top loose crust
		
		grid_canvas.draw_rect(rect, fill_color)
		
		# Border and cracks
		var border_col = Color(0.5, 0.55, 0.6)
		if tile.is_rock:
			border_col = Color(0.65, 0.45, 0.3)
		grid_canvas.draw_rect(rect, border_col, false, 1.5)
		
		# Crack lines if partially damaged
		if tile.layers < tile.max_layers:
			var p1 = rect.position + Vector2(10, 15)
			var p2 = rect.position + Vector2(TILE_WIDTH - 12, TILE_HEIGHT - 18)
			grid_canvas.draw_line(p1, p2, Color(0.1, 0.12, 0.14), 2.0)
		
		# Small layer indicators (dots)
		for dot in range(tile.layers):
			var dot_pos = rect.position + Vector2(12 + dot * 10, TILE_HEIGHT - 10)
			grid_canvas.draw_circle(dot_pos, 2.5, Color(1.0, 0.8, 0.2) if not tile.is_rock else Color(1.0, 0.4, 0.2))
	
	# 3. Draw Sparks
	for spark in hit_sparks:
		var alpha = 1.0 - (spark.life / spark.max_life)
		var c = spark.color
		c.a = alpha
		grid_canvas.draw_circle(spark.pos, 2.0, c)
