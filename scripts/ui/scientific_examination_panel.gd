extends CanvasLayer

# Echoes Beyond Earth — Catalogue Entry (Phase 5)
# ONE screen replaces the old "Scientific Examination" panel + the HUD "Discovery popup".
#
#   NAME  [stamp]                     (what you found; the stamp presses on once)
#   MISSION | YEAR | STATUS           (structured data row, no sentences)
#   ARCHIVE RECORD  | FIELD READINGS  (documented NASA record  |  in-game survey values)
#   [CONTINUE  Esc]   [WATCH STORY  E]
#
# Honesty rule: the left column is the documented record (purpose, size, account, sources); the
# right column is what the in-game survey instruments reported and carries a SIM badge. They are
# never mixed, and no fact is shown twice.
#
# Contract kept (artifact.gd, tests): script attached to a CanvasLayer, `artifact_id` set before
# add_child, signal documentation_closed(artifact_id), fields title_label / category_badge /
# measured_label / estimated_label, populate_data(), _on_close_pressed().
# New: signal story_requested(artifact_id) — emitted just before documentation_closed when the
# player chooses WATCH STORY.

signal documentation_closed(artifact_id: String)
signal story_requested(artifact_id: String)

const ARM_DELAY := 0.8      # keyboard ignored for this long so a held/pumped E cannot skip the entry
const CARD_WIDTH := 1040.0

var artifact_id: String = ""
var artifact_data: Dictionary = {}

var panel_container: PanelContainer
var title_label: Label
var category_badge: Label
var index_label: Label
var measured_label: Label
var estimated_label: Label
var close_button: Button        # CONTINUE
var story_button: Button        # WATCH STORY
var stamp: CatalogueStamp

var _root: Control
var _armed := false
var _closing := false
var _fields := {}               # Label per data key, filled by populate_data()


func _ready() -> void:
	layer = UITokens.LAYER_MODALS  # 20 — above overlays, below cinema
	add_to_group("blocking_modal")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_ui()
	populate_data()
	_play_entrance()
	story_button.call_deferred("grab_focus")


# ── Layout ───────────────────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITokens.theme()
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(UITokens.INK_900, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var card := ArchiveCard.new()
	card.show_offset_shadow = true
	var w := minf(CARD_WIDTH, get_viewport().get_visible_rect().size.x - 96.0)
	card.custom_minimum_size = Vector2(w, 0)
	center.add_child(card)
	panel_container = card

	var pad := MarginContainer.new()
	for side in ["left", "right"]:
		pad.add_theme_constant_override("margin_" + side, UITokens.SP_6)
	pad.add_theme_constant_override("margin_top", UITokens.SP_4)
	pad.add_theme_constant_override("margin_bottom", UITokens.SP_4)
	card.add_child(pad)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UITokens.SP_3)
	pad.add_child(col)

	# Gold rule: gold = archive / history (colour language of the whole game).
	var gold := ColorRect.new()
	gold.color = UITokens.SIGNAL_GOLD
	gold.custom_minimum_size = Vector2(0, 4)
	col.add_child(gold)

	# Header: category (left) · planet + position in the sequence (right)
	var head := HBoxContainer.new()
	col.add_child(head)
	category_badge = _caption("", UITokens.SIGNAL_GOLD)
	category_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(category_badge)
	index_label = _mono("", UITokens.PAPER_300, UITokens.TEXT_BODY)
	head.add_child(index_label)

	# Name + stamp
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", UITokens.SP_4)
	col.add_child(name_row)
	title_label = Label.new()
	title_label.theme_type_variation = &"DisplayLabel"
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	name_row.add_child(title_label)
	stamp = CatalogueStamp.new()
	stamp.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	name_row.add_child(stamp)

	# Data row: mission | year | status
	var data_row := HBoxContainer.new()
	data_row.add_theme_constant_override("separation", UITokens.SP_8)
	col.add_child(data_row)
	_add_cell(data_row, "mission", "MISSION", 3, false)
	_add_cell(data_row, "year", "YEAR", 0, true)
	_add_cell(data_row, "status", "STATUS", 5, false)

	col.add_child(_rule())

	# Two columns: archive record | field readings
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", UITokens.SP_6)
	col.add_child(cols)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", UITokens.SP_3)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.custom_minimum_size = Vector2(440, 0)
	cols.add_child(left)
	left.add_child(_badge_row(Badge.make(Badge.Kind.ARCHIVE)))
	_add_fact(left, "purpose", "PURPOSE")
	_add_fact(left, "size", "SIZE")
	_add_fact(left, "history", "ACCOUNT")
	_fields["sources"] = _caption("", UITokens.PAPER_500)
	_fields["sources"].autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_fields["sources"])

	var vrule := ColorRect.new()
	vrule.color = UITokens.INK_600
	vrule.custom_minimum_size = Vector2(1, 0)
	cols.add_child(vrule)

	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", UITokens.SP_3)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size = Vector2(440, 0)
	cols.add_child(right)
	right.add_child(_badge_row(Badge.make(Badge.Kind.SIM, "FIELD READINGS · IN-GAME")))
	_add_fact(right, "stratum", "STRATUM")
	_add_fact(right, "depth", "DEPTH", true)
	_add_fact(right, "signal", "SIGNAL")
	measured_label = _add_fact(right, "measured", "MEASURED")
	estimated_label = _add_fact(right, "estimated", "ESTIMATED")
	_add_fact(right, "context", "SETTING")

	col.add_child(_rule())

	# Actions
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", UITokens.SP_3)
	col.add_child(actions)
	var note := _caption("Either choice stores the specimen in your journal.", UITokens.PAPER_300)
	note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	actions.add_child(note)
	close_button = _action(actions, "ui_cancel", "Esc", "CONTINUE", &"GhostButton", _on_close_pressed)
	story_button = _action(actions, "interact", "", "WATCH STORY", &"PrimaryButton", _on_story_pressed)


func _caption(text: String, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"CaptionLabel"
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _mono(text: String, color: Color, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.theme_type_variation = &"StatLabel"
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _rule() -> ColorRect:
	var r := ColorRect.new()
	r.color = UITokens.INK_600
	r.custom_minimum_size = Vector2(0, 1)
	return r


func _badge_row(b: Badge) -> Control:
	var row := HBoxContainer.new()
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	row.add_child(b)
	return row


## Cell of the data row: caption title over a value (mono for numbers).
func _add_cell(parent: Control, key: String, title: String, ratio: int, mono: bool) -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	if ratio > 0:
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.size_flags_stretch_ratio = float(ratio)
	parent.add_child(v)
	v.add_child(_caption(title, UITokens.PAPER_300))
	var val: Label
	if mono:
		val = _mono("", UITokens.PAPER_100, UITokens.TEXT_LEAD)
	else:
		val = Label.new()
		val.theme_type_variation = &"LeadLabel"
		val.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		val.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(val)
	_fields[key] = val


## Caption + body text pair. Returns the body label.
func _add_fact(parent: Control, key: String, title: String, mono: bool = false) -> Label:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	parent.add_child(v)
	v.add_child(_caption(title, UITokens.PAPER_300))
	var body: Label
	if mono:
		body = _mono("", UITokens.PAPER_100, UITokens.TEXT_BODY)
	else:
		body = Label.new()
		body.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
		body.add_theme_color_override("font_color", UITokens.PAPER_100)
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(body)
	_fields[key] = body
	# Hide the whole pair when a value is missing (never show an invented placeholder).
	body.set_meta("pair", v)
	return body


func _action(parent: Control, action: String, cap_text: String, label_text: String, variation: StringName, handler: Callable) -> Button:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", UITokens.SP_2)
	parent.add_child(box)
	var cap := KeyCap.new()
	cap.action_name = action
	if cap_text != "":
		cap.label_override = cap_text
	box.add_child(cap)
	var btn := Button.new()
	btn.text = label_text
	btn.theme_type_variation = variation
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.pressed.connect(handler)
	box.add_child(btn)
	return btn


# ── Data ─────────────────────────────────────────────────────────────────────────────────

func populate_data() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs and artifact_data.is_empty():
		artifact_data = gs.get_artifact_data(artifact_id)
	if artifact_data.is_empty():
		return
	var d := artifact_data

	title_label.text = str(d.get("name", artifact_id))
	category_badge.text = str(d.get("category", "Scientific Discoveries")).to_upper()
	index_label.text = _entry_index(gs, d)

	_put("mission", str(d.get("mission", "")))
	_put("year", _format_year(d.get("year", "")))
	_put("status", str(d.get("status", "")))

	_put("purpose", str(d.get("purpose", "")))
	_put("size", _size_text(d))
	_put("history", str(d.get("history", "")))
	var srcs: Array = d.get("sources", [])
	var sources := _fields["sources"] as Label
	sources.text = ("Sources: " + "; ".join(PackedStringArray(srcs))) if not srcs.is_empty() else ""
	sources.visible = not srcs.is_empty()

	_put("stratum", str(d.get("stratigraphic_layer", "")))
	if d.has("discovery_depth_cm"):
		_put("depth", "%.1f cm" % float(d["discovery_depth_cm"]))
	else:
		_put("depth", "")
	_put("signal", str(d.get("detection_signature", "")))
	_put("measured", str(d.get("measured_properties", "")))
	_put("estimated", str(d.get("estimated_properties", "")))
	_put("context", str(d.get("geological_context", "")))


func _put(key: String, text: String) -> void:
	var l := _fields[key] as Label
	l.text = text
	if l.has_meta("pair"):  # 4.7 logs an error for get_meta() on a missing key even with a default
		var pair = l.get_meta("pair")
		if pair is Control:
			(pair as Control).visible = text != ""


## "MOON · 03 / 07" — same order and numbering as the journal, so the two always agree.
func _entry_index(gs, d: Dictionary) -> String:
	if gs == null:
		return ""
	var planet := str(d.get("location", ""))
	var idx := 0
	var total := 0
	for id in gs.artifacts_data.keys():
		if str(gs.artifacts_data[id].get("location", "")).to_lower() != planet.to_lower():
			continue
		total += 1
		if id == artifact_id:
			idx = total
	if idx == 0:
		return planet.to_upper()
	return "%s · %02d / %02d" % [planet.to_upper(), idx, total]


func _size_text(d: Dictionary) -> String:
	var parts: PackedStringArray = []
	if d.has("dimensions_cm"):
		parts.append(str(d["dimensions_cm"]).replace(" x ", " × "))
	if d.has("mass_kg"):
		var m := float(d["mass_kg"])
		parts.append(("%d kg" % int(m)) if is_equal_approx(m, roundf(m)) else ("%.1f kg" % m))
	return "  ·  ".join(parts)


# Years are floats in some JSON paths; never print "1971.0" (audit B3).
func _format_year(v) -> String:
	if v is float or v is int:
		return str(int(v))
	return str(v)


# ── Motion ───────────────────────────────────────────────────────────────────────────────

func _play_entrance() -> void:
	var m := SettingsStore.motion_scale()
	if m > 0.0:
		panel_container.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(panel_container, "modulate:a", 1.0, UITokens.DURATION_BASE * m)
		tw.tween_interval(UITokens.DURATION_BASE * m)
		tw.tween_callback(stamp.slam)
	else:
		stamp.slam()
	get_tree().create_timer(ARM_DELAY).timeout.connect(func() -> void: _armed = true)


# ── Input ────────────────────────────────────────────────────────────────────────────────
# _input (not _unhandled_input): this modal must consume Esc / E / Enter BEFORE the HUD (pause),
# the player (mouse release) and the artifact (interact) see them. One key, one meaning.

func _input(event: InputEvent) -> void:
	if _closing:
		return
	var is_cancel := event.is_action_pressed("ui_cancel")
	var is_story := event.is_action_pressed("interact")
	var is_accept := event.is_action_pressed("ui_accept")
	if not (is_cancel or is_story or is_accept):
		return
	get_viewport().set_input_as_handled()
	if not _armed:
		return           # swallowed during the arm delay
	if is_cancel:
		_on_close_pressed()
	elif is_story:
		_on_story_pressed()
	else:
		# Enter / Space / gamepad A: activate whatever has focus (WATCH STORY by default).
		var f := get_viewport().gui_get_focus_owner()
		if f is Button:
			(f as Button).pressed.emit()
		else:
			_on_story_pressed()


func _on_story_pressed() -> void:
	if _closing:
		return
	_closing = true
	story_requested.emit(artifact_id)
	_finish()


func _on_close_pressed() -> void:
	if _closing:
		return
	_closing = true
	_finish()


func _finish() -> void:
	documentation_closed.emit(artifact_id)
	queue_free()
