extends Control

## Echoes Beyond Earth — Component Gallery (Dev/QA scene)
## Instantiates every Phase 2 component and shows all states.
## Run this scene directly in Godot to validate the design system.
## NOT shipped in release builds.
##
## Controls:
##   [T]  — trigger a Toast notification cycle (info / success / warning / error)
##   [ESC] — quit gallery

const THEME_PATH := "res://ui/theme/ebe_theme.tres"

@onready var scroll: ScrollContainer = $Scroll
@onready var vbox: VBoxContainer     = $Scroll/VBox

func _ready() -> void:
	# Apply the EBE theme to the whole gallery
	var t := load(THEME_PATH)
	if t:
		theme = t
	else:
		push_warning("ComponentGallery: theme not found at " + THEME_PATH)

	# Dark backdrop matching ink-900
	var bg := ColorRect.new()
	bg.set_anchors_preset(PRESET_FULL_RECT)
	bg.color = UITokens.INK_900
	bg.z_index = -1
	add_child(bg)

	_build_gallery()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_T:
				_demo_toasts()
			KEY_ESCAPE:
				get_tree().quit()

func _build_gallery() -> void:
	_add_title("ECHOES BEYOND EARTH — COMPONENT GALLERY")
	_add_subtitle("Phase 2 · Design System · Direction A: Declassified Archive")
	_spacer()

	# ── PALETTE SWATCHES ───────────────────────────────────────
	_section("COLOUR TOKENS")
	_add_swatches()
	_spacer()

	# ── TYPOGRAPHY ─────────────────────────────────────────────
	_section("TYPOGRAPHY SCALE")
	_add_type_specimens()
	_spacer()

	# ── BUTTONS ────────────────────────────────────────────────
	_section("BUTTON STATES")
	_add_buttons()
	_spacer()

	# ── KEY CAPS ───────────────────────────────────────────────
	_section("KEY CAPS (from InputMap)")
	_add_keycaps()
	_spacer()

	# ── STAT READOUTS ──────────────────────────────────────────
	_section("STAT READOUTS")
	_add_stat_readouts()
	_spacer()

	# ── SEGMENTED METERS ───────────────────────────────────────
	_section("SEGMENTED METERS")
	_add_meters()
	_spacer()

	# ── SECTION HEADERS ────────────────────────────────────────
	_section("SECTION HEADERS")
	var sh1 := SectionHeader.new()
	sh1.title = "ARCHIVE RECORD"
	vbox.add_child(sh1)
	var sh2 := SectionHeader.new()
	sh2.title = "FIELD READINGS (SIM)"
	vbox.add_child(sh2)
	_spacer()

	# ── ARCHIVE CARDS ──────────────────────────────────────────
	_section("ARCHIVE CARDS")
	_add_cards()
	_spacer()

	# ── PROGRESS BAR ───────────────────────────────────────────
	_section("PROGRESS BAR (themed)")
	var pb := ProgressBar.new()
	pb.custom_minimum_size.y = 18
	pb.value = 65
	pb.show_percentage = true
	vbox.add_child(pb)
	_spacer()

	# ── SEPARATOR ──────────────────────────────────────────────
	_section("SEPARATOR")
	var sep := HSeparator.new()
	vbox.add_child(sep)
	_spacer()

	_add_footer()

# ── HELPERS ──────────────────────────────────────────────────

func _add_title(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", UITokens.TEXT_DISPLAY)
	l.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD)
	vbox.add_child(l)

func _add_subtitle(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
	l.add_theme_color_override("font_color", UITokens.PAPER_300)
	vbox.add_child(l)

func _section(text: String) -> void:
	var sh := SectionHeader.new()
	sh.title = text
	vbox.add_child(sh)

func _spacer(height: int = 16) -> void:
	var c := Control.new()
	c.custom_minimum_size.y = height
	vbox.add_child(c)

func _add_swatches() -> void:
	var tokens := {
		"ink-900": UITokens.INK_900, "ink-800": UITokens.INK_800,
		"ink-700": UITokens.INK_700, "ink-600": UITokens.INK_600,
		"paper-100": UITokens.PAPER_100, "paper-300": UITokens.PAPER_300,
		"paper-500": UITokens.PAPER_500,
		"gold": UITokens.SIGNAL_GOLD, "cyan": UITokens.SIGNAL_CYAN,
		"red": UITokens.SIGNAL_RED, "green": UITokens.SIGNAL_GREEN,
	}
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 8)
	vbox.add_child(row)

	for token_name in tokens:
		var col: Color = tokens[token_name]
		var swatch := PanelContainer.new()
		swatch.custom_minimum_size = Vector2(80, 48)
		var sb := StyleBoxFlat.new()
		sb.bg_color = col
		sb.set_border_width_all(1)
		sb.border_color = UITokens.INK_600
		swatch.add_theme_stylebox_override("panel", sb)

		var l := Label.new()
		l.text = token_name
		l.add_theme_font_size_override("font_size", 10)
		# Choose readable text: dark on light swatches
		l.add_theme_color_override("font_color",
			UITokens.INK_900 if col.get_luminance() > 0.4 else UITokens.PAPER_100)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		swatch.add_child(l)
		row.add_child(swatch)

func _add_type_specimens() -> void:
	var sizes := [
		["TEXT_HERO (40)",    UITokens.TEXT_HERO,    UITokens.PAPER_100],
		["TEXT_DISPLAY (28)", UITokens.TEXT_DISPLAY,  UITokens.PAPER_100],
		["TEXT_TITLE (20)",   UITokens.TEXT_TITLE,    UITokens.PAPER_100],
		["TEXT_LEAD (16)",    UITokens.TEXT_LEAD,     UITokens.PAPER_100],
		["TEXT_BODY (14)",    UITokens.TEXT_BODY,     UITokens.PAPER_300],
		["TEXT_CAPTION (12)", UITokens.TEXT_CAPTION,  UITokens.PAPER_500],
	]
	for entry in sizes:
		var l := Label.new()
		l.text = entry[0] + " — The quick brown fox"
		l.add_theme_font_size_override("font_size", entry[1])
		l.add_theme_color_override("font_color", entry[2])
		vbox.add_child(l)

func _add_buttons() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)

	for label in ["Normal", "Hover→", "Pressed", "Disabled"]:
		var b := Button.new()
		b.text = label
		if label == "Disabled":
			b.disabled = true
		row.add_child(b)

func _add_keycaps() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	vbox.add_child(row)

	var actions := [
		["interact",        ""],
		["toggle_journal",  ""],
		["ui_accept",       ""],
		["ui_cancel",       ""],
		["",                "SPACE"],   # label override demo
	]
	for entry in actions:
		var kc := KeyCap.new()
		kc.action_name    = entry[0]
		kc.label_override = entry[1]
		row.add_child(kc)

func _add_stat_readouts() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 32)
	vbox.add_child(row)

	var data := [
		["HEART RATE", "82",     "BPM",        UITokens.SIGNAL_GOLD],
		["HEADING",    "045°",   "NNE",         UITokens.PAPER_100],
		["GRAVITY",    "1.62",   "m/s²",        UITokens.SIGNAL_CYAN],
		["PLSS O2",    "98.4",   "%  SIM",      UITokens.SIGNAL_GREEN],
	]
	for d in data:
		var sr := StatReadout.new()
		sr.title        = d[0]
		sr.value        = d[1]
		sr.unit         = d[2]
		sr.accent_color = d[3]
		row.add_child(sr)

func _add_meters() -> void:
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	vbox.add_child(col)

	for fill_v in [0.2, 0.5, 0.8, 1.0]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		col.add_child(row)

		var lbl := Label.new()
		lbl.text = "%d%%" % int(fill_v * 100)
		lbl.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
		lbl.add_theme_color_override("font_color", UITokens.PAPER_500)
		lbl.custom_minimum_size.x = 36
		row.add_child(lbl)

		var m := SegmentedMeter.new()
		m.segment_count = 10
		m.custom_minimum_size = Vector2(200, 16)
		m.value = fill_v
		row.add_child(m)

func _add_cards() -> void:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 16)
	row.add_theme_constant_override("v_separation", 16)
	vbox.add_child(row)

	# Plain card
	var card1 := ArchiveCard.new()
	card1.custom_minimum_size = Vector2(200, 80)
	var l1 := Label.new()
	l1.text = "ARCHIVE CARD\nPlain border"
	l1.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
	card1.add_child(l1)
	row.add_child(card1)

	# Card with hard-offset shadow
	var card2 := ArchiveCard.new()
	card2.show_offset_shadow = true
	card2.custom_minimum_size = Vector2(200, 80)
	var l2 := Label.new()
	l2.text = "ARCHIVE CARD\nWith 4,4 shadow"
	l2.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
	card2.add_child(l2)
	row.add_child(card2)

	# HUD panel
	var hud := HudPanel.new()
	hud.custom_minimum_size = Vector2(200, 80)
	var l3 := Label.new()
	l3.text = "HUD PANEL\nTranslucent"
	l3.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
	hud.add_child(l3)
	row.add_child(hud)

func _add_footer() -> void:
	var sep := HSeparator.new()
	vbox.add_child(sep)
	var l := Label.new()
	l.text = "Press [T] — demo toasts   |   [ESC] — quit gallery"
	l.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
	l.add_theme_color_override("font_color", UITokens.PAPER_500)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(l)

func _demo_toasts() -> void:
	var messages := [
		["Signal acquired",   UITokens.SIGNAL_CYAN],
		["Specimen stored",   UITokens.SIGNAL_GREEN],
		["Mars unlocked",     UITokens.SIGNAL_GOLD],
		["Low O2 — SIM",      UITokens.SIGNAL_RED],
	]
	var delay := 0.0
	for m in messages:
		var timer := get_tree().create_timer(delay)
		var msg: String = m[0]
		var col: Color  = m[1]
		timer.timeout.connect(func(): Toast.notify(get_tree(), msg, col))
		delay += 1.5
