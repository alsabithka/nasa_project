class_name WorldHud
extends Control

## Echoes Beyond Earth — WorldHud (Phase 4)
## The in-world HUD layout. Zones (24 px safe margin, nothing may overlap):
##   top-left     mission + progress            (this node)
##   top-right    Journal / Pause buttons       (this node)
##   bottom-right scanner instrument            (this node)
##   bottom-left  suit telemetry                (astronaut_helmet_hud.gd, layer 5)
##   centre       reticle (first-person only) and optional contextual prompt
## Buttons never take keyboard focus: the mouse is captured during play, and a focused
## button would fire on Space (jump) or Enter.

signal journal_pressed
signal pause_pressed

const MARGIN := 24

var location_label: Label
var counter_label: Label
var scanner: ScannerInstrument
var journal_button: Button
var menu_button: Button

var _progress_meter: SegmentedMeter
var _prompt_panel: HudPanel
var _prompt_cap: KeyCap
var _prompt_text: Label
var _reticle_on: bool = false
var _player: Node = null


func _ready() -> void:
	add_to_group("world_hud")   # Phase 5: artifacts show/hide the contextual prompt through this group
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = UITokens.theme()
	_build_mission_zone()
	_build_button_zone()
	_build_scanner_zone()
	_build_prompt()
	resized.connect(queue_redraw)


# ── Zones ──────────────────────────────────────────────────────────────────────────────

func _build_mission_zone() -> void:
	var panel := HudPanel.new()
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override("separation", UITokens.SP_1)
	panel.add_child(col)
	location_label = Label.new()
	location_label.theme_type_variation = &"LeadLabel"
	location_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(location_label)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UITokens.SP_3)
	col.add_child(row)
	counter_label = Label.new()
	counter_label.theme_type_variation = &"StatLabel"
	counter_label.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD)
	counter_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(counter_label)
	_progress_meter = SegmentedMeter.new()
	_progress_meter.accent = UITokens.SIGNAL_GOLD
	_progress_meter.custom_minimum_size = Vector2(96, 10)
	_progress_meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_progress_meter)
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT, Control.PRESET_MODE_MINSIZE, MARGIN)


func _build_button_zone() -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UITokens.SP_4)
	journal_button = _make_button(row, "Journal", "journal", "toggle_journal", "")
	menu_button = _make_button(row, "Pause", "pause", "", "Esc")
	journal_button.pressed.connect(func() -> void: journal_pressed.emit())
	menu_button.pressed.connect(func() -> void: pause_pressed.emit())
	add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, MARGIN)
	row.grow_horizontal = Control.GROW_DIRECTION_BEGIN


## [key-cap] [icon Label] in one row. Returns the button.
func _make_button(parent: Control, text: String, icon_name: String, action: String, cap_text: String) -> Button:
	var holder := HBoxContainer.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	holder.add_theme_constant_override("separation", UITokens.SP_2)
	parent.add_child(holder)
	var cap := KeyCap.new()
	if action != "":
		cap.action_name = action
	else:
		cap.label_override = cap_text
	holder.add_child(cap)
	var b := Button.new()
	b.text = text
	b.icon = UITokens.icon(icon_name)
	b.theme_type_variation = &"GhostButton"
	b.focus_mode = Control.FOCUS_NONE
	holder.add_child(b)
	return b


func _build_scanner_zone() -> void:
	scanner = ScannerInstrument.new()
	add_child(scanner)
	scanner.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, MARGIN)
	scanner.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	scanner.grow_vertical = Control.GROW_DIRECTION_BEGIN


func _build_prompt() -> void:
	_prompt_panel = HudPanel.new()
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UITokens.SP_3)
	_prompt_panel.add_child(row)
	_prompt_cap = KeyCap.new()
	row.add_child(_prompt_cap)
	_prompt_text = Label.new()
	_prompt_text.theme_type_variation = &"LeadLabel"
	_prompt_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_prompt_text)
	_prompt_panel.visible = false
	add_child(_prompt_panel)
	_prompt_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_prompt_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_prompt_panel.offset_bottom = -float(MARGIN + 96)


# ── Public API ─────────────────────────────────────────────────────────────────────────

func set_progress(planet: String, found: int, total: int) -> void:
	location_label.text = planet.to_upper()
	counter_label.text = "%d / %d" % [found, total]
	_progress_meter.segment_count = maxi(1, total)
	_progress_meter.value = float(found) / float(maxi(1, total))


## Contextual prompt: a key-cap read from the InputMap plus a verb ("Begin excavation").
func show_prompt(action: String, verb: String) -> void:
	_prompt_cap.action_name = action
	_prompt_cap.label_override = ""
	_prompt_text.text = verb
	_prompt_panel.visible = true


func hide_prompt() -> void:
	_prompt_panel.visible = false


## Hide / show everything that sits over the world (used while a modal is open).
func set_world_zones_visible(v: bool) -> void:
	scanner.visible = v


# ── Reticle (first-person only) ────────────────────────────────────────────────────────

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		return
	var fp: bool = bool(_player.get("is_first_person")) if "is_first_person" in _player else false
	var on: bool = fp and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
	if on != _reticle_on:
		_reticle_on = on
		queue_redraw()


func _draw() -> void:
	if not _reticle_on:
		return
	var c: Vector2 = size * 0.5
	var col := Color(UITokens.PAPER_100, 0.85)
	var gap: float = 5.0
	var tick: float = 7.0
	draw_line(c + Vector2(-gap - tick, 0), c + Vector2(-gap, 0), col, 2.0)
	draw_line(c + Vector2(gap, 0), c + Vector2(gap + tick, 0), col, 2.0)
	draw_line(c + Vector2(0, -gap - tick), c + Vector2(0, -gap), col, 2.0)
	draw_line(c + Vector2(0, gap), c + Vector2(0, gap + tick), col, 2.0)
