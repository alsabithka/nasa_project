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
var depth_bar: SegmentedMeter
var combo_label: Label
var status_label: Label
var status_icon: TextureRect
var burst_badge: Badge
var audio_player: AudioStreamPlayer

const DEFAULT_STATUS := "Click tiles to drill the regolith. Every 5th consecutive hit is a power burst."
const BURST_FLASH_TIME := 0.6
var _burst_flash: float = 0.0

# Particles
var hit_sparks: Array = []

func _ready() -> void:
	layer = UITokens.LAYER_MODALS  # was 15 (merge §9.3)
	add_to_group("blocking_modal")  # journal / pause hotkeys inert while open (merge §9.2)
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

func _label(text: String, variation: StringName, color: Color = Color.TRANSPARENT) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	if color.a > 0.0:
		l.add_theme_color_override("font_color", color)
	return l

func _build_ui() -> void:
	# Backdrop scrim stays still; only panel_root shakes (so the edges never show the world behind).
	var bg = ColorRect.new()
	bg.name = "BackgroundScrim"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = UITokens.INK_900
	bg.color.a = 0.86
	add_child(bg)

	panel_root = Control.new()
	panel_root.name = "PanelRoot"
	panel_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_root.theme = UITokens.theme()
	add_child(panel_root)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_root.add_child(center)

	var frame := ArchiveCard.new()
	frame.name = "Frame"
	center.add_child(frame)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", UITokens.SP_3)
	frame.add_child(vbox)

	# Header
	vbox.add_child(_label("SUBSURFACE EXCAVATION", &"TitleLabel"))
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override("separation", UITokens.SP_2)
	vbox.add_child(status_row)
	status_icon = UITokens.make_icon("check", UITokens.SIGNAL_GREEN, 16)
	status_icon.visible = false
	status_row.add_child(status_icon)
	status_label = _label(DEFAULT_STATUS, &"CaptionLabel", UITokens.PAPER_300)
	status_row.add_child(status_label)

	# Center area: vertical depth gauge + grid
	var grid_size := Vector2(COLS * TILE_WIDTH + (COLS - 1) * GRID_GAP, ROWS * TILE_HEIGHT + (ROWS - 1) * GRID_GAP)
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", UITokens.SP_4)
	vbox.add_child(hbox)

	var depth_box = VBoxContainer.new()
	depth_box.add_theme_constant_override("separation", UITokens.SP_1)
	var depth_title := _label("DEPTH", &"CaptionLabel", UITokens.PAPER_300)
	depth_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	depth_box.add_child(depth_title)
	depth_bar = SegmentedMeter.new()
	depth_bar.vertical = true
	depth_bar.segment_count = 10
	depth_bar.accent = UITokens.SIGNAL_CYAN
	depth_bar.custom_minimum_size = Vector2(16, grid_size.y - 24.0)
	depth_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	depth_box.add_child(depth_bar)
	hbox.add_child(depth_box)

	grid_canvas = Control.new()
	grid_canvas.name = "GridCanvas"
	grid_canvas.custom_minimum_size = grid_size
	grid_canvas.gui_input.connect(_on_grid_gui_input)
	grid_canvas.draw.connect(_on_grid_draw)
	hbox.add_child(grid_canvas)

	# Footer: combo + power burst badge + rock legend ... cancel
	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", UITokens.SP_4)
	vbox.add_child(footer)

	combo_label = _label("COMBO 0×", &"StatLabel", UITokens.PAPER_500)
	combo_label.custom_minimum_size = Vector2(120, 0)
	footer.add_child(combo_label)

	var badge_slot := Control.new()  # fixed slot so the badge appearing never shifts the footer
	badge_slot.custom_minimum_size = Vector2(150, 24)
	footer.add_child(badge_slot)
	burst_badge = Badge.make(Badge.Kind.ARCHIVE, "POWER BURST")
	burst_badge.visible = false
	badge_slot.add_child(burst_badge)

	var legend := HBoxContainer.new()
	legend.add_theme_constant_override("separation", UITokens.SP_2)
	legend.add_child(UITokens.make_icon("warning", UITokens.SIGNAL_RED, 14))
	var legend_text := _label("ROCK: needs extra hits", &"CaptionLabel", UITokens.PAPER_300)
	legend_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	legend.add_child(legend_text)
	footer.add_child(legend)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(spacer)

	var cancel_row := HBoxContainer.new()
	cancel_row.add_theme_constant_override("separation", UITokens.SP_2)
	var cancel_btn = Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.theme_type_variation = &"GhostButton"
	cancel_btn.focus_mode = Control.FOCUS_NONE
	cancel_btn.pressed.connect(_cancel)
	cancel_row.add_child(cancel_btn)
	var cap := KeyCap.new()
	cap.label_override = "Esc"
	cancel_row.add_child(cap)
	footer.add_child(cancel_row)

func _set_status(text: String, color: Color, ok_icon: bool = false, lead: bool = false) -> void:
	status_label.text = text
	status_label.theme_type_variation = &"LeadLabel" if lead else &"CaptionLabel"
	status_label.add_theme_color_override("font_color", color)
	status_icon.visible = ok_icon

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
		var amp: float = screen_shake * SettingsStore.motion_scale()  # reduced motion = no shake
		panel_root.position = Vector2(randf_range(-amp, amp), randf_range(-amp, amp))
	else:
		panel_root.position = Vector2.ZERO

	if _burst_flash > 0.0:
		_burst_flash -= delta
		if _burst_flash <= 0.0:
			burst_badge.visible = false
			if not is_won:
				_set_status(DEFAULT_STATUS, UITokens.PAPER_300)
	
	if grid_canvas:
		grid_canvas.queue_redraw()

func _input(event: InputEvent) -> void:
	# Esc policy (merge §9.1): this modal is on top, so it closes first and consumes the event.
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
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
	_set_status("Power burst: adjacent tiles cleared", UITokens.SIGNAL_GOLD)
	burst_badge.visible = true
	_burst_flash = BURST_FLASH_TIME
	
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
	count = int(round(count * SettingsStore.motion_scale()))  # reduced motion = no sparks
	for i in range(count):
		var ang = randf() * TAU
		var spd = randf_range(40.0, 160.0)
		hit_sparks.append({
			"pos": origin,
			"vel": Vector2(cos(ang), sin(ang)) * spd,
			"life": 0.0,
			"max_life": randf_range(0.25, 0.50),
			"color": UITokens.PAPER_300 if randf() < 0.6 else UITokens.SIGNAL_GOLD
		})

func _update_combo_ui() -> void:
	combo_label.text = "COMBO %d×" % combo_count
	combo_label.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD if combo_count > 0 else UITokens.PAPER_500)

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
		_burst_flash = 0.0
		burst_badge.visible = false
		_set_status("ARTIFACT EXPOSED", UITokens.SIGNAL_GREEN, true, true)

func _tile_rect(tile: Dictionary) -> Rect2:
	return Rect2(tile.x * (TILE_WIDTH + GRID_GAP), tile.y * (TILE_HEIGHT + GRID_GAP), TILE_WIDTH, TILE_HEIGHT)

## Diagonal hatch clipped to `rect` (rocks differ by SHAPE, not only colour).
func _draw_hatch(rect: Rect2, col: Color) -> void:
	var step := 12.0
	var d := step
	while d < rect.size.x + rect.size.y:
		var a := Vector2(minf(d, rect.size.x), d - minf(d, rect.size.x))
		var b := Vector2(d - minf(d, rect.size.y), minf(d, rect.size.y))
		grid_canvas.draw_line(rect.position + a, rect.position + b, col, 1.0)
		d += step

func _on_grid_draw() -> void:
	# 1. Tiles
	for tile in tiles:
		var rect := _tile_rect(tile)

		if tile.cleared:
			if tile.is_artifact:
				# exposed artifact tile: gold 2 px outline + dig marker (diamond), no cyan glow
				grid_canvas.draw_rect(rect, UITokens.INK_700)
				grid_canvas.draw_rect(rect.grow(-1.0), UITokens.SIGNAL_GOLD, false, 2.0)
				var mk := UITokens.icon("signal_dig")
				if mk:
					grid_canvas.draw_texture_rect(mk, Rect2(rect.get_center() - Vector2(10, 10), Vector2(20, 20)), false, UITokens.SIGNAL_GOLD)
			else:
				grid_canvas.draw_rect(rect, UITokens.INK_600, false, 1.0)  # faint cleared cell
			continue

		# Remaining layers: more layers = darker (ink steps)
		var fill_color: Color
		match tile.layers:
			3: fill_color = UITokens.INK_800
			2: fill_color = UITokens.INK_700
			_: fill_color = UITokens.INK_600
		grid_canvas.draw_rect(rect, fill_color)

		if tile.is_rock:
			_draw_hatch(rect, UITokens.PAPER_500)
			var wi := UITokens.icon("warning")
			if wi:
				grid_canvas.draw_texture_rect(wi, Rect2(rect.position + Vector2(TILE_WIDTH - 22, 6), Vector2(16, 16)), false, UITokens.SIGNAL_RED)

		grid_canvas.draw_rect(rect, UITokens.PAPER_500, false, 1.0)

		# Crack line if partially damaged
		if tile.layers < tile.max_layers:
			var p1 = rect.position + Vector2(10, 15)
			var p2 = rect.position + Vector2(TILE_WIDTH - 12, TILE_HEIGHT - 18)
			grid_canvas.draw_line(p1, p2, UITokens.INK_900, 2.0)

		# Layer pips: squares (PAPER_300; rocks SIGNAL_RED)
		var pip_col := UITokens.SIGNAL_RED if tile.is_rock else UITokens.PAPER_300
		for dot in range(tile.layers):
			var pp = rect.position + Vector2(9 + dot * 11, TILE_HEIGHT - 13)
			grid_canvas.draw_rect(Rect2(pp, Vector2(7, 7)), pip_col)

	# 2. Won: one gold frame around the whole exposed artifact (static; no flashing)
	if is_won:
		var sil := Rect2(2 * (TILE_WIDTH + GRID_GAP), 1 * (TILE_HEIGHT + GRID_GAP), 4 * TILE_WIDTH + 3 * GRID_GAP, 3 * TILE_HEIGHT + 2 * GRID_GAP)
		grid_canvas.draw_rect(sil.grow(2.0), UITokens.SIGNAL_GOLD, false, 2.0)

	# 3. Sparks
	for spark in hit_sparks:
		var alpha = 1.0 - (spark.life / spark.max_life)
		var c: Color = spark.color
		c.a = alpha
		grid_canvas.draw_rect(Rect2(spark.pos - Vector2(1.5, 1.5), Vector2(3, 3)), c)
