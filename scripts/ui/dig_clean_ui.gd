extends CanvasLayer

# Echoes Beyond Earth - Field Specimen Conservation (cleaning mini-game)
# integrated1 mechanics (manual mouse scrubbing of a 160x160 dirt mask, crust patches, 94.8 % rule)
# under the harsh "Declassified Archive" chrome. The specimen being uncovered is harsh's vector
# probe (SpecimenReveal in static mode). Merge plan §8.2.
# Emits cleaning_done(artifact_id) 1.2 s after the specimen is cleaned.

signal cleaning_done(artifact_id: String)

@export var artifact_id: String = ""
@export var clean_duration: float = 6.0  # kept for compatibility, unused (manual scrubbing)

const MASK_SIZE: int = 160
const BRUSH_RADIUS: float = 18.0
const PLATE_SIZE := Vector2(440, 240)
const METER_SEGMENTS: int = 20
const DONE_DELAY: float = 1.2

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
var specimen: SpecimenReveal
var progress_meter: SegmentedMeter
var percent_label: Label
var state_label: Label
var tool_icon: TextureRect
var tool_label: Label
var tool_status: Label
var subtitle_label: Label
var audio_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer

var last_mouse_pos: Vector2 = Vector2.ZERO
var _cursor_layer: Control
var _particle_canvas: Control
var _hover_pos: Vector2 = Vector2.ZERO
var _hovering: bool = false
var _fade_t: float = -1.0
var _fade_start: Image

func _ready() -> void:
	layer = UITokens.LAYER_MODALS  # was 15 (merge §9.3)
	add_to_group("blocking_modal")  # journal / pause hotkeys inert while open (merge §9.2)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_setup_audio()
	_init_dirt_mask()
	_build_ui()
	_update_labels()
	_update_state_text()

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

	# Fill with granular regolith: grain between the two dust tokens, crust patches darker (INK_700)
	for y in range(MASK_SIZE):
		for x in range(MASK_SIZE):
			var col: Color = UITokens.INK_600.lerp(UITokens.DUST_LIGHT, rng.randf())
			col.a = 0.96
			for patch in crust_patches:
				var dist = Vector2(x - patch.x, y - patch.y).length()
				if dist < patch.z:
					col = UITokens.INK_700  # darker, compacted crust
					col.a = 1.0
			dirt_image.set_pixel(x, y, col)

	dirt_texture = ImageTexture.create_from_image(dirt_image)

func _label(text: String, variation: StringName, color: Color = Color.TRANSPARENT) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = variation
	if color.a > 0.0:
		l.add_theme_color_override("font_color", color)
	return l

func _key_hint(cap_text: String, words: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UITokens.SP_2)
	var cap := KeyCap.new()
	cap.label_override = cap_text
	row.add_child(cap)
	var l := _label(words, &"CaptionLabel", UITokens.PAPER_300)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(l)
	return row

func _build_ui() -> void:
	# Scrim (INK_900 @ 0.9; swallows clicks so nothing behind the modal is reachable)
	var bg = ColorRect.new()
	bg.name = "BackgroundScrim"
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = UITokens.INK_900
	bg.color.a = 0.9
	add_child(bg)

	var center = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.theme = UITokens.theme()
	add_child(center)

	var panel := ArchiveCard.new()
	panel.name = "PanelContainer"
	panel.custom_minimum_size = Vector2(500, 0)
	center.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.add_theme_constant_override("separation", UITokens.SP_3)
	panel.add_child(vbox)

	# Header
	vbox.add_child(_label("FIELD SPECIMEN CONSERVATION", &"TitleLabel"))
	subtitle_label = _label("Scrub the dust away to reveal the specimen.", &"CaptionLabel", UITokens.PAPER_300)
	subtitle_label.name = "Subtitle"
	vbox.add_child(subtitle_label)

	# Instrument row: brush icon + tool name ... state words (icon is tinted gold only while scrubbing)
	var tool_row := HBoxContainer.new()
	tool_row.name = "InstrumentStatusHBox"
	tool_row.add_theme_constant_override("separation", UITokens.SP_2)
	vbox.add_child(tool_row)
	tool_icon = UITokens.make_icon("brush", UITokens.PAPER_500, 16)
	tool_row.add_child(tool_icon)
	tool_label = _label("ULTRASONIC BRUSH", &"CaptionLabel", UITokens.PAPER_300)
	tool_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tool_row.add_child(tool_label)
	tool_status = _label("IDLE", &"CaptionLabel", UITokens.PAPER_300)
	tool_row.add_child(tool_status)

	# Preview plate: specimen picture (bottom) -> dirt mask -> dust puffs -> brush cursor (top)
	var plate := Control.new()
	plate.name = "PreviewPlate"
	plate.custom_minimum_size = PLATE_SIZE
	plate.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(plate)

	specimen = SpecimenReveal.new()
	specimen.show_dust = false  # the manual mask is the only dust
	specimen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	plate.add_child(specimen)
	specimen.custom_minimum_size = PLATE_SIZE  # SpecimenReveal._ready sets its own min size; override after

	preview_rect = TextureRect.new()
	preview_rect.name = "DirtMask"
	preview_rect.custom_minimum_size = PLATE_SIZE
	preview_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	preview_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview_rect.stretch_mode = TextureRect.STRETCH_SCALE
	preview_rect.texture = dirt_texture
	preview_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	preview_rect.gui_input.connect(_on_preview_gui_input)
	preview_rect.mouse_exited.connect(_on_plate_mouse_exited)
	plate.add_child(preview_rect)

	_particle_canvas = Control.new()
	_particle_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_particle_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_particle_canvas.draw.connect(_on_particle_canvas_draw)
	plate.add_child(_particle_canvas)

	_cursor_layer = Control.new()
	_cursor_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cursor_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor_layer.draw.connect(_on_cursor_draw)
	plate.add_child(_cursor_layer)

	# State line
	state_label = _label("", &"LeadLabel", UITokens.PAPER_300)
	state_label.name = "StateLabel"
	vbox.add_child(state_label)

	# Progress: segmented meter (percent_clean stays the single source of truth) + percent readout
	var meter_row := HBoxContainer.new()
	meter_row.add_theme_constant_override("separation", UITokens.SP_3)
	vbox.add_child(meter_row)
	progress_meter = SegmentedMeter.new()
	progress_meter.name = "ProgressMeter"
	progress_meter.segment_count = METER_SEGMENTS
	progress_meter.accent = UITokens.SIGNAL_CYAN
	progress_meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	meter_row.add_child(progress_meter)
	percent_label = _label("0 %", &"StatLabel")
	percent_label.custom_minimum_size = Vector2(64, 0)
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	meter_row.add_child(percent_label)

	# Key hints (the mouse has no icon in the set, so the cap carries the word)
	var hints := HBoxContainer.new()
	hints.name = "Hints"
	vbox.add_child(hints)
	hints.add_child(_key_hint("LMB", "Drag to scrub away dust"))
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hints.add_child(sp)
	hints.add_child(_key_hint("Esc", "Cancel"))

func _update_labels() -> void:
	var gs = get_node_or_null("/root/GameState")
	var art_data = gs.get_artifact_data(artifact_id) if gs else {}
	if not art_data.is_empty() and subtitle_label:
		var name_str = art_data.get("name", "NASA SPECIMEN")
		var year_val = art_data.get("year", "HISTORICAL")
		var year_str = str(int(year_val)) if (year_val is float or year_val is int) else str(year_val)
		subtitle_label.text = "TARGET: %s [%s]" % [name_str.to_upper(), year_str]

## Neutral copy on purpose (works for rocks and hardware). Words + colour, never colour alone.
func _update_state_text() -> void:
	if state_label == null:
		return
	var txt := "Unidentified subsurface anomaly"
	var col := UITokens.PAPER_300
	if is_complete:
		txt = "Cleaned and preserved"
		col = UITokens.SIGNAL_GOLD
	elif percent_clean >= 90.0:
		txt = "Identification imminent"
		col = UITokens.SIGNAL_CYAN
	elif percent_clean >= 60.0:
		txt = "Form emerging from the dust"
	elif percent_clean >= 30.0:
		txt = "Surface structure detected"
	state_label.text = txt
	state_label.add_theme_color_override("font_color", col)

func _set_scrubbing(on: bool) -> void:
	is_scrubbing = on
	if is_complete or tool_icon == null:
		return
	tool_icon.modulate = UITokens.SIGNAL_GOLD if on else UITokens.PAPER_500
	tool_status.text = "SCRUBBING" if on else "IDLE"
	tool_status.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD if on else UITokens.PAPER_300)

func _process(delta: float) -> void:
	if _fade_t >= 0.0:
		_step_fade(delta)
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
	if _particle_canvas:
		_particle_canvas.queue_redraw()

func _input(event: InputEvent) -> void:
	# Esc policy (merge §9.1): this modal is on top, so it closes first and consumes the event.
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_cancel()

func _cancel() -> void:
	if is_complete:
		return  # already cleaned: the specimen is safe, the 1.2 s hand-off to the catalogue is running
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

func _on_plate_mouse_exited() -> void:
	_hovering = false
	if _cursor_layer:
		_cursor_layer.queue_redraw()

func _on_preview_gui_input(event: InputEvent) -> void:
	if is_complete:
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_set_scrubbing(event.pressed)
			if is_scrubbing:
				if audio_player and not audio_player.playing:
					audio_player.play()
				_apply_brush(event.position)
			else:
				if audio_player and audio_player.playing:
					audio_player.stop()
	elif event is InputEventMouseMotion:
		_hover_pos = event.position
		_hovering = true
		if _cursor_layer:
			_cursor_layer.queue_redraw()
		if is_scrubbing:
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
	_refresh_progress()

	if (percent_clean >= 94.8 or round(percent_clean) >= 95.0) and not is_complete:
		_on_cleaning_complete()

func _refresh_progress() -> void:
	if progress_meter == null:
		return
	progress_meter.value = percent_clean / 100.0  # percent_clean is the single source of truth
	percent_label.text = "%d %%" % int(round(percent_clean))
	_update_state_text()

func _on_cleaning_complete() -> void:
	is_complete = true
	if audio_player and audio_player.playing:
		audio_player.stop()
	is_scrubbing = false
	_hovering = false
	if _cursor_layer:
		_cursor_layer.queue_redraw()

	# Remaining dust fades out over DURATION_BASE (instant at reduced motion)
	var fade_time: float = UITokens.DURATION_BASE * SettingsStore.motion_scale()
	if fade_time <= 0.0:
		dirt_image.fill(Color.TRANSPARENT)
		dirt_texture.update(dirt_image)
	else:
		_fade_start = dirt_image.duplicate()
		_fade_t = 0.0

	_play_success_chime()
	percent_clean = 100.0
	_refresh_progress()
	progress_meter.accent = UITokens.SIGNAL_GOLD
	tool_icon.texture = UITokens.icon("check")
	tool_icon.modulate = UITokens.SIGNAL_GREEN
	tool_label.text = "PRESERVATION COMPLETE"
	tool_status.text = "DONE"
	tool_status.add_theme_color_override("font_color", UITokens.SIGNAL_GREEN)

	var timer = get_tree().create_timer(DONE_DELAY)
	timer.timeout.connect(_emit_done)

func _emit_done() -> void:
	cleaning_done.emit(artifact_id)

func _step_fade(delta: float) -> void:
	var total: float = UITokens.DURATION_BASE * SettingsStore.motion_scale()
	_fade_t += delta
	var k: float = 1.0 - clampf(_fade_t / maxf(total, 0.001), 0.0, 1.0)
	if k <= 0.0:
		dirt_image.fill(Color.TRANSPARENT)
		_fade_t = -1.0
		_fade_start = null
	else:
		for y in range(MASK_SIZE):
			for x in range(MASK_SIZE):
				var c: Color = _fade_start.get_pixel(x, y)
				if c.a > 0.0:
					c.a *= k
					dirt_image.set_pixel(x, y, c)
	dirt_texture.update(dirt_image)

func _on_particle_canvas_draw() -> void:
	for p in dust_puffs:
		var alpha = 1.0 - (p.life / p.max_life)
		var col: Color = UITokens.PAPER_500.lerp(UITokens.PAPER_300, 0.5)
		col.a = alpha * 0.45
		_particle_canvas.draw_circle(p.pos, p.radius, col)

## Brush cursor: the mask is stretched over the plate, so the circular brush is an ellipse on screen.
func _on_cursor_draw() -> void:
	if not _hovering or is_complete:
		return
	var sx: float = PLATE_SIZE.x / float(MASK_SIZE)
	var sy: float = PLATE_SIZE.y / float(MASK_SIZE)
	_cursor_layer.draw_set_transform(_hover_pos, 0.0, Vector2(sx, sy))
	_cursor_layer.draw_arc(Vector2.ZERO, BRUSH_RADIUS, 0.0, TAU, 40, UITokens.SIGNAL_GOLD, 1.5 / minf(sx, sy))
	_cursor_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
