extends CanvasLayer

# Echoes Beyond Earth — Field Manual / Onboarding (Phase 3)
# Shows once on first run; 3 cards: SCAN → DIG → CATALOGUE
# Layer: UITokens.LAYER_CINEMA (30) — above HUD, below system modals
# Persists first_run_shown in user://settings.cfg

signal manual_closed

const UITokens = preload("res://scripts/ui/ui_tokens.gd")
const CFG_PATH := "user://settings.cfg"

var _current_page: int = 0

var _pages := [
	{
		"step":  "01",
		"title": "SCAN THE SURFACE",
		"body":  "Equip your Proximity Scanner and walk the terrain. The signal strength bar rises as you approach a buried artefact. Audio pulses accelerate — follow the rhythm.",
		"key_action": "No key required — scanner is always active",
		"glyph": "◆",
	},
	{
		"step":  "02",
		"title": "EXCAVATE",
		"body":  "When the scanner reads ANOMALY BENEATH SURFACE, press [E] to begin excavation. Use the cleaning tool to uncover the artefact layer by layer.",
		"key_action": "interact",
		"glyph": "▲",
	},
	{
		"step":  "03",
		"title": "CATALOGUE",
		"body":  "Each recovered object is logged in your Archaeological Journal [J]. Read the declassified NASA mission notes and build your complete archive of lunar and Martian history.",
		"key_action": "toggle_journal",
		"glyph": "●",
	},
]

# Node references built in _build_ui
var _overlay: ColorRect
var _card: PanelContainer
var _glyph_label: Label
var _step_label: Label
var _title_label: Label
var _body_label: RichTextLabel
var _key_label: Label
var _prev_btn: Button
var _next_btn: Button
var _skip_btn: Button
var _page_dots: HBoxContainer


func _ready() -> void:
	layer = UITokens.LAYER_CINEMA
	_build_ui()
	_refresh_page()
	visible = false


# ─── Show / hide ──────────────────────────────────────────────────────────────

static func should_show() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(CFG_PATH) != OK:
		return true
	return not cfg.get_value("settings", "first_run_shown", false)


func show_manual() -> void:
	_current_page = 0
	_refresh_page()
	visible = true


func _mark_shown() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CFG_PATH)
	cfg.set_value("settings", "first_run_shown", true)
	cfg.save(CFG_PATH)


# ─── UI construction ──────────────────────────────────────────────────────────

func _build_ui() -> void:
	_overlay = ColorRect.new()
	_overlay.anchors_preset = Control.PRESET_FULL_RECT
	_overlay.color = Color(UITokens.INK_900, 0.82)
	add_child(_overlay)

	_card = PanelContainer.new()
	_card.set_anchors_preset(Control.PRESET_CENTER)
	_card.offset_left = -300.0
	_card.offset_top = -230.0
	_card.offset_right = 300.0
	_card.offset_bottom = 230.0
	_card.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card.grow_vertical = Control.GROW_DIRECTION_BOTH

	var sty := StyleBoxFlat.new()
	sty.bg_color = UITokens.INK_800
	sty.border_width_left = 3
	sty.border_width_top = 3
	sty.border_width_right = 3
	sty.border_width_bottom = 3
	sty.border_color = UITokens.SIGNAL_GOLD
	sty.content_margin_left = 40.0
	sty.content_margin_top = 32.0
	sty.content_margin_right = 40.0
	sty.content_margin_bottom = 32.0
	_card.add_theme_stylebox_override("panel", sty)
	add_child(_card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	_card.add_child(vbox)

	# Top: "FIELD MANUAL" label + skip
	var header_row := HBoxContainer.new()
	vbox.add_child(header_row)

	var manual_lbl := Label.new()
	manual_lbl.text = "FIELD MANUAL"
	manual_lbl.add_theme_color_override("font_color", UITokens.PAPER_500)
	manual_lbl.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
	manual_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(manual_lbl)

	_skip_btn = Button.new()
	_skip_btn.text = "Skip"
	_skip_btn.flat = true
	_skip_btn.add_theme_color_override("font_color", UITokens.PAPER_500)
	_skip_btn.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
	_skip_btn.pressed.connect(_on_close)
	header_row.add_child(_skip_btn)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Large glyph
	_glyph_label = Label.new()
	_glyph_label.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD)
	_glyph_label.add_theme_font_size_override("font_size", UITokens.TEXT_HERO)
	_glyph_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_glyph_label)

	# Step counter  e.g. "STEP 01 / 03"
	_step_label = Label.new()
	_step_label.add_theme_color_override("font_color", UITokens.PAPER_500)
	_step_label.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
	_step_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_step_label)

	# Title
	_title_label = Label.new()
	_title_label.add_theme_color_override("font_color", UITokens.PAPER_100)
	_title_label.add_theme_font_size_override("font_size", UITokens.TEXT_DISPLAY)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_title_label)

	# Body text
	_body_label = RichTextLabel.new()
	_body_label.bbcode_enabled = true
	_body_label.scroll_active = false
	_body_label.add_theme_color_override("default_color", UITokens.PAPER_300)
	_body_label.add_theme_font_size_override("normal_font_size", UITokens.TEXT_BODY)
	_body_label.custom_minimum_size = Vector2(0, 90)
	_body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_body_label)

	# Key hint
	_key_label = Label.new()
	_key_label.add_theme_color_override("font_color", UITokens.SIGNAL_CYAN)
	_key_label.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
	_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_key_label)

	var sep2 := HSeparator.new()
	vbox.add_child(sep2)

	# Navigation row
	var nav_row := HBoxContainer.new()
	nav_row.add_theme_constant_override("separation", 12)
	vbox.add_child(nav_row)

	_prev_btn = Button.new()
	_prev_btn.text = "← PREV"
	_prev_btn.flat = true
	_prev_btn.add_theme_color_override("font_color", UITokens.PAPER_300)
	_prev_btn.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
	_prev_btn.pressed.connect(_on_prev)
	nav_row.add_child(_prev_btn)

	# Page dots
	_page_dots = HBoxContainer.new()
	_page_dots.add_theme_constant_override("separation", 8)
	_page_dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_page_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	for _i in _pages.size():
		var dot := Label.new()
		dot.text = "●"
		dot.add_theme_font_size_override("font_size", 10)
		_page_dots.add_child(dot)
	nav_row.add_child(_page_dots)

	_next_btn = Button.new()
	_next_btn.text = "NEXT →"
	_next_btn.flat = true
	_next_btn.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD)
	_next_btn.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
	_next_btn.pressed.connect(_on_next)
	nav_row.add_child(_next_btn)


# ─── Page logic ───────────────────────────────────────────────────────────────

func _refresh_page() -> void:
	var p := _pages[_current_page]

	_glyph_label.text = p["glyph"]
	_step_label.text  = "STEP %s / %02d" % [p["step"], _pages.size()]
	_title_label.text = p["title"]
	_body_label.text  = p["body"]

	# Key hint — resolve InputMap action if applicable
	var action: String = p["key_action"]
	if InputMap.has_action(action):
		var events := InputMap.action_get_events(action)
		for ev in events:
			if ev is InputEventKey:
				_key_label.text = "[ %s ]" % OS.get_keycode_string(ev.keycode)
				break
	else:
		_key_label.text = action

	# Dots
	for i in _page_dots.get_child_count():
		var dot: Label = _page_dots.get_child(i)
		if i == _current_page:
			dot.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD)
		else:
			dot.add_theme_color_override("font_color", UITokens.PAPER_500)

	_prev_btn.visible = _current_page > 0
	_next_btn.text = "BEGIN EXPLORATION →" if _current_page == _pages.size() - 1 else "NEXT →"


func _on_prev() -> void:
	if _current_page > 0:
		_current_page -= 1
		_refresh_page()


func _on_next() -> void:
	if _current_page < _pages.size() - 1:
		_current_page += 1
		_refresh_page()
	else:
		_on_close()


func _on_close() -> void:
	_mark_shown()
	visible = false
	emit_signal("manual_closed")


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_RIGHT, KEY_SPACE:
				_on_next()
				get_viewport().set_input_as_handled()
			KEY_LEFT:
				_on_prev()
				get_viewport().set_input_as_handled()
			KEY_ESCAPE:
				_on_close()
				get_viewport().set_input_as_handled()
