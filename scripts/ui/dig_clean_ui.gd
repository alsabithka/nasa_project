extends CanvasLayer

# Echoes Beyond Earth - Interactive Specimen Decontamination Minigame
# Allows astronaut to scrub away lunar regolith using an ultrasonic decontaminator brush.
# Emits cleaning_done(artifact_id) when specimen is 95% cleaned.

signal cleaning_done(artifact_id: String)

@export var artifact_id: String = ""
@export var clean_duration: float = 6.0

const MASK_SIZE: int = 160
const BRUSH_RADIUS: float = 18.0

var dirt_image: Image
var dirt_texture: ImageTexture
var mask_dirty: bool = false
var is_scrubbing: bool = false
var is_complete: bool = false
var percent_clean: float = 0.0

# Crust patches: Array of Vector3 (center_x, center_y, radius)
var crust_patches: Array = []

# Particles and visual feedback
var dust_puffs: Array = []

# UI references
var preview_rect: TextureRect
var specimen_canvas: Control
var progress_bar: ProgressBar
var percent_label: Label
var brush_hint: Label
var status_led: Label
var audio_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var last_mouse_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	layer = 15
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_setup_audio()
	_init_dirt_mask()
	_build_ui()
	_update_labels()

func _setup_audio() -> void:
	# Continuous soft scrubbing noise
	audio_player = AudioStreamPlayer.new()
	audio_player.name = "ScrubNoise"
	audio_player.bus = &"Master"
	audio_player.volume_db = -24.0
	add_child(audio_player)
	
	var sample_rate = 22050
	var duration = 1.0
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var noise = (randf() * 2.0 - 1.0) * 0.18
		var sample_val = clampi(int(noise * 32767.0), -32767, 32767)
		var u16 = sample_val if sample_val >= 0 else (sample_val + 65536)
		data[i * 2] = u16 & 0xFF
		data[i * 2 + 1] = (u16 >> 8) & 0xFF
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = num_samples
	wav.data = data
	audio_player.stream = wav
	
	# One-shot sfx player
	sfx_player = AudioStreamPlayer.new()
	sfx_player.name = "SFXPlayer"
	sfx_player.bus = &"Master"
	sfx_player.volume_db = -10.0
	add_child(sfx_player)

func _play_success_chime() -> void:
	var sample_rate = 22050
	var duration = 0.80
	var num_samples = int(sample_rate * duration)
	var data = PackedByteArray()
	data.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / float(sample_rate)
		var env = clampf(1.0 - t / duration, 0.0, 1.0)
		# Ascending triad: 587Hz (D5), 740Hz (F#5), 880Hz (A5)
		var wave = (sin(t * 587.33 * TAU) * 0.35 + sin(t * 739.99 * TAU) * 0.35 + sin(t * 880.00 * TAU) * 0.35) * env
		var sample_val = clampi(int(wave * 32767.0 * 0.5), -32767, 32767)
		var u16 = sample_val if sample_val >= 0 else (sample_val + 65536)
		data[i * 2] = u16 & 0xFF
		data[i * 2 + 1] = (u16 >> 8) & 0xFF
	
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = data
	sfx_player.stream = wav
	sfx_player.play()

func _init_dirt_mask() -> void:
	dirt_image = Image.create(MASK_SIZE, MASK_SIZE, false, Image.FORMAT_RGBA8)
	var rng = RandomNumberGenerator.new()
	rng.seed = hash(artifact_id) if not artifact_id.is_empty() else 98765
	
	# Seed 2-3 stubborn crust patches
	crust_patches.clear()
	var patch_count = rng.randi_range(2, 3)
	for i in range(patch_count):
		var cx = rng.randf_range(35.0, 125.0)
		var cy = rng.randf_range(35.0, 125.0)
		var rad = rng.randf_range(20.0, 32.0)
		crust_patches.append(Vector3(cx, cy, rad))
	
	# Fill with granular lunar regolith dirt (alpha ~ 0.95)
	for y in range(MASK_SIZE):
		for x in range(MASK_SIZE):
			var grit = rng.randf_range(0.20, 0.28)
			var alpha = 0.96
			# Check if inside a stubborn crust patch
			for patch in crust_patches:
				var dist = Vector2(x - patch.x, y - patch.y).length()
				if dist < patch.z:
					grit = 0.16 # Darker, compacted crust
					alpha = 1.0
			dirt_image.set_pixel(x, y, Color(grit, grit + 0.02, grit + 0.04, alpha))
	
	dirt_texture = ImageTexture.create_from_image(dirt_image)

func _build_ui() -> void:
	# Scrim
	var bg = ColorRect.new()
	bg.name = "BackgroundScrim"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.035, 0.05, 0.92)
	add_child(bg)
	
	# Center Frame
	var center = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var panel = PanelContainer.new()
	panel.name = "PanelContainer"
	panel.custom_minimum_size = Vector2(520, 480)
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.07, 0.11, 0.96)
	sb.border_color = Color(0.0, 0.9, 1.0, 0.85)
	sb.set_border_width_all(2)
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", sb)
	center.add_child(panel)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)
	
	# Header
	var title = Label.new()
	title.text = "// FIELD SPECIMEN DECONTAMINATION CHAMBER //"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.65, 0.1))
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)
	
	var subtitle = Label.new()
	subtitle.name = "Subtitle"
	subtitle.text = "TARGET: SUB-SURFACE HISTORICAL ARTIFACT"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0, 0.85))
	subtitle.add_theme_font_size_override("font_size", 12)
	vbox.add_child(subtitle)
	
	# Status line
	var hbox_status = HBoxContainer.new()
	hbox_status.name = "InstrumentStatusHBox"
	hbox_status.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_status.add_theme_constant_override("separation", 16)
	vbox.add_child(hbox_status)
	
	status_led = Label.new()
	status_led.name = "StatusLed"
	status_led.text = "● TOOL: ULTRASONIC DECONTAMINATOR"
	status_led.add_theme_color_override("font_color", Color(0.2, 0.9, 0.4))
	status_led.add_theme_font_size_override("font_size", 11)
	hbox_status.add_child(status_led)
	
	var tool_hint = Label.new()
	tool_hint.text = "DRAG MOUSE TO SCRUB // ESC TO CANCEL"
	tool_hint.add_theme_color_override("font_color", Color(0.65, 0.75, 0.85))
	tool_hint.add_theme_font_size_override("font_size", 11)
	hbox_status.add_child(tool_hint)
	
	# Preview Box: Contains Specimen Visual Canvas and Dirt Layer TextureRect
	var preview_box = PanelContainer.new()
	preview_box.custom_minimum_size = Vector2(440, 240)
	var sb_prev = StyleBoxFlat.new()
	sb_prev.bg_color = Color(0.02, 0.04, 0.06, 0.95)
	sb_prev.border_color = Color(0.0, 0.9, 1.0, 0.5)
	sb_prev.set_border_width_all(1)
	preview_box.add_theme_stylebox_override("panel", sb_prev)
	vbox.add_child(preview_box)
	
	# 1. Specimen Blueprint / Artwork layer (drawn underneath dirt)
	specimen_canvas = Control.new()
	specimen_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	specimen_canvas.draw.connect(_on_specimen_canvas_draw)
	preview_box.add_child(specimen_canvas)
	
	# 2. Dirt Mask TextureRect (covers specimen)
	preview_rect = TextureRect.new()
	preview_rect.custom_minimum_size = Vector2(440, 240)
	preview_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_rect.stretch_mode = TextureRect.STRETCH_SCALE
	preview_rect.texture = dirt_texture
	preview_rect.gui_input.connect(_on_preview_gui_input)
	preview_box.add_child(preview_rect)
	
	# 3. Particle overlay for dust puffs
	var particle_canvas = Control.new()
	particle_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	particle_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	particle_canvas.draw.connect(_on_particle_canvas_draw)
	preview_box.add_child(particle_canvas)
	
	# Progress bar
	progress_bar = ProgressBar.new()
	progress_bar.name = "ProgressBar"
	progress_bar.custom_minimum_size = Vector2(0, 16)
	progress_bar.max_value = 100.0
	progress_bar.value = 0.0
	progress_bar.show_percentage = false
	vbox.add_child(progress_bar)
	
	percent_label = Label.new()
	percent_label.text = "0% DECONTAMINATED"
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	percent_label.add_theme_color_override("font_color", Color(0.9, 0.95, 0.98))
	percent_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(percent_label)
	
	brush_hint = Label.new()
	brush_hint.name = "BrushHint"
	brush_hint.text = "CLICK & DRAG TO SCRUB AWAY REGOLITH"
	brush_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	brush_hint.add_theme_color_override("font_color", Color(1.0, 0.65, 0.1))
	brush_hint.add_theme_font_size_override("font_size", 12)
	vbox.add_child(brush_hint)

func _update_labels() -> void:
	var gs = get_node_or_null("/root/GameState")
	var art_data = gs.get_artifact_data(artifact_id) if gs else {}
	if not art_data.is_empty():
		var name_str = art_data.get("name", "NASA SPECIMEN")
		var year_str = str(art_data.get("year", "HISTORICAL"))
		var sub = get_node_or_null("CenterContainer/PanelContainer/VBoxContainer/Subtitle")
		if sub:
			sub.text = "TARGET: %s [%s]" % [name_str.to_upper(), year_str]

func _process(delta: float) -> void:
	if is_complete:
		return
	
	if mask_dirty and dirt_texture:
		dirt_texture.update(dirt_image)
		mask_dirty = false
		_calculate_clean_percentage()
	
	# Dust puffs animation
	var alive_puffs = []
	for p in dust_puffs:
		p.life += delta
		p.pos += p.vel * delta
		if p.life < p.max_life:
			alive_puffs.append(p)
	dust_puffs = alive_puffs

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		_cancel()

func _cancel() -> void:
	if audio_player and audio_player.playing:
		audio_player.stop()
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("end_interaction"):
		player.end_interaction()
	if player and player.has_method("capture_mouse"):
		player.capture_mouse()
	var parent_art = get_parent()
	if parent_art and parent_art.has_method("_set_state"):
		parent_art._set_state(parent_art.ArtifactState.EXPOSED)
	queue_free()

func _on_preview_gui_input(event: InputEvent) -> void:
	if is_complete:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_scrubbing = event.pressed
			if is_scrubbing:
				if audio_player and not audio_player.playing:
					audio_player.play()
				_apply_brush(event.position)
			else:
				if audio_player and audio_player.playing:
					audio_player.stop()
	elif event is InputEventMouseMotion and is_scrubbing:
		_apply_brush(event.position)

func _apply_brush(ui_pos: Vector2) -> void:
	var rect_size = preview_rect.size if preview_rect else Vector2.ZERO
	if rect_size.x <= 0 or rect_size.y <= 0:
		rect_size = Vector2(440, 240)
	
	var norm_x = ui_pos.x / rect_size.x
	var norm_y = ui_pos.y / rect_size.y
	var img_cx = int(clampf(norm_x * float(MASK_SIZE), 0.0, float(MASK_SIZE - 1)))
	var img_cy = int(clampf(norm_y * float(MASK_SIZE), 0.0, float(MASK_SIZE - 1)))
	
	# Soft circular brush
	var rad_int = int(BRUSH_RADIUS)
	for dy in range(-rad_int, rad_int + 1):
		var py = img_cy + dy
		if py < 0 or py >= MASK_SIZE:
			continue
		for dx in range(-rad_int, rad_int + 1):
			var px = img_cx + dx
			if px < 0 or px >= MASK_SIZE:
				continue
			var dist = sqrt(float(dx * dx + dy * dy))
			if dist <= BRUSH_RADIUS:
				var falloff = 1.0 - (dist / BRUSH_RADIUS)
				# Check if in crust patch (takes extra passes)
				var removal_rate = 0.55
				for patch in crust_patches:
					if Vector2(px - patch.x, py - patch.y).length() < patch.z:
						removal_rate = 0.28
						break
				
				var cur_col = dirt_image.get_pixel(px, py)
				var new_alpha = maxf(0.0, cur_col.a - falloff * removal_rate)
				cur_col.a = new_alpha
				dirt_image.set_pixel(px, py, cur_col)
	
	mask_dirty = true
	
	# Spawn dust particles
	for i in range(2):
		dust_puffs.append({
			"pos": ui_pos + Vector2(randf_range(-12, 12), randf_range(-12, 12)),
			"vel": Vector2(randf_range(-30, 30), randf_range(-40, -10)),
			"life": 0.0,
			"max_life": randf_range(0.2, 0.4),
			"radius": randf_range(3.0, 7.0)
		})

func _calculate_clean_percentage() -> void:
	# Sample on a coarse 4px grid (40x40 = 1600 samples)
	var step = 4
	var total_samples = 0
	var clean_samples = 0
	
	for y in range(0, MASK_SIZE, step):
		for x in range(0, MASK_SIZE, step):
			total_samples += 1
			var col = dirt_image.get_pixel(x, y)
			if col.a <= 0.15:
				clean_samples += 1
	
	percent_clean = (float(clean_samples) / float(total_samples)) * 100.0
	progress_bar.value = percent_clean
	percent_label.text = "%d%% DECONTAMINATED" % int(round(percent_clean))
	
	if (percent_clean >= 94.8 or round(percent_clean) >= 95.0) and not is_complete:
		_on_cleaning_complete()

func _on_cleaning_complete() -> void:
	is_complete = true
	if audio_player and audio_player.playing:
		audio_player.stop()
	
	# Auto-clear remaining dust mask to pristine transparency
	dirt_image.fill(Color(0, 0, 0, 0))
	dirt_texture.update(dirt_image)
	
	_play_success_chime()
	progress_bar.value = 100.0
	percent_label.text = "100% SPECIMEN RESTORED"
	percent_label.add_theme_color_override("font_color", Color(0.2, 0.95, 0.5))
	brush_hint.text = "★ SPECIMEN RESTORED & CATALOGED ★"
	brush_hint.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	status_led.text = "● PRESERVATION: SUCCESSFUL"
	status_led.add_theme_color_override("font_color", Color(0.2, 0.95, 0.5))
	
	var timer = get_tree().create_timer(1.2)
	timer.timeout.connect(func():
		cleaning_done.emit(artifact_id)
	)

func _on_specimen_canvas_draw() -> void:
	var sz = specimen_canvas.size
	var center = sz * 0.5
	
	# Draw technical coordinate grid and blueprint background
	for x in range(0, int(sz.x), 40):
		specimen_canvas.draw_line(Vector2(x, 0), Vector2(x, sz.y), Color(0.0, 0.9, 1.0, 0.08))
	for y in range(0, int(sz.y), 40):
		specimen_canvas.draw_line(Vector2(0, y), Vector2(sz.x, y), Color(0.0, 0.9, 1.0, 0.08))
	
	# Stylized Specimen Blueprint Shape
	# Outer sensor radar circle
	specimen_canvas.draw_arc(center, 75.0, 0.0, TAU, 48, Color(0.0, 0.9, 1.0, 0.4), 2.0)
	specimen_canvas.draw_arc(center, 50.0, 0.0, TAU, 36, Color(0.0, 0.9, 1.0, 0.6), 1.5)
	specimen_canvas.draw_arc(center, 25.0, 0.0, TAU, 24, Color(0.0, 0.9, 1.0, 0.8), 2.0)
	
	# Technical crosshairs and aerospace corner markers
	specimen_canvas.draw_line(center - Vector2(90, 0), center + Vector2(90, 0), Color(0.0, 0.9, 1.0, 0.35), 1.0)
	specimen_canvas.draw_line(center - Vector2(0, 90), center + Vector2(0, 90), Color(0.0, 0.9, 1.0, 0.35), 1.0)
	
	# Inner golden historical core
	specimen_canvas.draw_circle(center, 18.0, Color(1.0, 0.8, 0.2, 0.85))
	specimen_canvas.draw_rect(Rect2(center.x - 30, center.y - 12, 60, 24), Color(0.2, 0.7, 0.9, 0.5), false, 2.0)

func _on_particle_canvas_draw() -> void:
	for p in dust_puffs:
		var alpha = 1.0 - (p.life / p.max_life)
		var col = Color(0.65, 0.7, 0.78, alpha * 0.45)
		preview_rect.draw_circle(p.pos, p.radius, col)
