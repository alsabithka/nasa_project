class_name JournalDrawer
extends CanvasLayer

## Echoes Beyond Earth — JournalDrawer (Phase 6)
## The field journal as an archive drawer: planet tabs, category filters with progress,
## a grid of numbered silhouette slots, and a detail panel with progressive disclosure
## (key facts first, "READ MORE" for the narrative).
##
## Public contract (used by hud.gd and tests):
##   open(planet := "")   close()   refresh()   show_planet(planet)   select_artifact(id)   is_open()
##   signals: closed, story_requested(artifact_id)
##   fields:  planet, category_filter, selected_id, slots (Array[JournalSlot]), filter_buttons,
##            tabs, detail_name, read_more_button, story_button
##
## Honesty rules:
##   * Only the ARCHIVE record is shown here (documented facts from data/artifacts.json).
##     Simulated in-game readings live in the Catalogue Entry, not in the journal.
##   * Locked slots never show a name or a category. With SPOILER_FREE = false the category
##     FILTERS still count found/total per category (progress per category, as designed);
##     set it to true to hide those totals and the locked slots in filtered views.
##
## Esc is consumed here (the top modal closes first; pause opens only when no modal is open).

signal closed
signal story_requested(artifact_id: String)

const SPOILER_FREE := false
const PLANETS: Array[String] = ["Moon", "Mars"]
const MAX_CARD := Vector2(1120, 640)
const FLASHBACK_PATH := "res://data/flashbacks.json"

var planet: String = "Moon"
var category_filter: String = ""        # "" = all categories
var selected_id: String = ""

var slots: Array[JournalSlot] = []
var filter_buttons: Array[Button] = []
var tabs: ArchiveTabs
var detail_name: Label
var read_more_button: Button
var story_button: Button
var close_button: Button
var card: PanelContainer

var _root: Control
var _total_label: Label
var _planet_meter: SegmentedMeter
var _planet_count: Label
var _notice_row: HBoxContainer
var _filter_flow: HFlowContainer
var _filter_group: ButtonGroup
var _grid: GridContainer
var _scroll: ScrollContainer
var _detail_col: VBoxContainer
var _detail_scroll: ScrollContainer
var _expanded := false
var _return_focus: Control = null
var _open := false
static var _story_cache: Dictionary = {}


func _ready() -> void:
	layer = UITokens.LAYER_MODALS
	_build_shell()
	visible = false


func is_open() -> bool:
	return _open


# ── Data access ─────────────────────────────────────────────────────────────────────────

func _gs() -> Node:
	return get_node_or_null("/root/GameState")


## Artifact ids of one planet, in data order (the same order the Catalogue Entry numbers by).
func _ids_for(p: String) -> Array:
	var gs = _gs()
	var out: Array = []
	if gs == null:
		return out
	for id in gs.artifacts_data.keys():
		if str(gs.artifacts_data[id].get("location", "")).to_lower() == p.to_lower():
			out.append(id)
	return out


func _is_found(id: String) -> bool:
	var gs = _gs()
	return gs != null and gs.is_artifact_recovered(id)


func _data(id: String) -> Dictionary:
	var gs = _gs()
	return gs.get_artifact_data(id) if gs != null else {}


## Distinct categories of a planet, in first-seen order.
func _categories_for(p: String) -> Array:
	var cats: Array = []
	for id in _ids_for(p):
		var c := str(_data(id).get("category", ""))
		if c != "" and not cats.has(c):
			cats.append(c)
	return cats


func _found_total(ids: Array) -> Vector2i:
	var found := 0
	for id in ids:
		if _is_found(id):
			found += 1
	return Vector2i(found, ids.size())


## True when a story (documentary video or text flashback) exists for this artifact.
static func has_story(id: String) -> bool:
	if _story_cache.is_empty():
		var ids := {}
		if FileAccess.file_exists(FLASHBACK_PATH):
			var f := FileAccess.open(FLASHBACK_PATH, FileAccess.READ)
			var parsed = JSON.parse_string(f.get_as_text()) if f != null else null
			if parsed is Dictionary and parsed.get("flashbacks") is Dictionary:
				for k in parsed["flashbacks"].keys():
					ids[k] = true
		_story_cache = ids
		_story_cache["__loaded"] = true
	if _story_cache.has(id):
		return true
	var manifest = load("res://scripts/ui/artifact_video_manifest.gd")
	return manifest != null and manifest.is_playable(id)


# ── Open / close ────────────────────────────────────────────────────────────────────────

func open(start_planet: String = "") -> void:
	if _root == null:
		push_warning("JournalDrawer.open() called before the node entered the tree")
		return
	if start_planet != "":
		planet = start_planet
	_return_focus = get_viewport().gui_get_focus_owner()
	_open = true
	visible = true
	category_filter = ""
	_expanded = false
	_rebuild_all()
	var d: float = UITokens.DURATION_BASE * SettingsStore.motion_scale()
	if d > 0.0:
		card.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(card, "modulate:a", 1.0, d)
	else:
		card.modulate.a = 1.0
	_focus_first.call_deferred()


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	if _return_focus != null and is_instance_valid(_return_focus) and _return_focus.is_inside_tree() and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus()
	closed.emit()


## Re-reads GameState (call when an artifact is catalogued while the drawer is open).
func refresh() -> void:
	if _root != null:
		_rebuild_all()


func show_planet(p: String) -> void:
	planet = p
	category_filter = ""
	_expanded = false
	if _root != null:
		_rebuild_all()


func select_artifact(id: String) -> void:
	selected_id = id
	_expanded = false
	for s in slots:
		s.selected = s.artifact_id == id
	_build_detail()


func _focus_first() -> void:
	if not _open:
		return
	for s in slots:
		if s.artifact_id == selected_id and s.is_inside_tree():
			s.grab_focus()
			return
	if not slots.is_empty():
		slots[0].grab_focus()
	elif close_button != null:
		close_button.grab_focus()


func _input(event: InputEvent) -> void:
	if _open and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


# ── Build ───────────────────────────────────────────────────────────────────────────────

func _build_shell() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITokens.theme()
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(UITokens.INK_900, 0.88)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP     # B7: nothing behind the journal shows through
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var arch := ArchiveCard.new()
	arch.show_offset_shadow = true
	var vp := get_viewport().get_visible_rect().size
	arch.custom_minimum_size = Vector2(minf(MAX_CARD.x, vp.x - 64.0), minf(MAX_CARD.y, vp.y - 64.0))
	center.add_child(arch)
	card = arch

	var pad := MarginContainer.new()
	pad.add_theme_constant_override("margin_left", UITokens.SP_6)
	pad.add_theme_constant_override("margin_right", UITokens.SP_6)
	pad.add_theme_constant_override("margin_top", UITokens.SP_4)
	pad.add_theme_constant_override("margin_bottom", UITokens.SP_4)
	arch.add_child(pad)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UITokens.SP_3)
	pad.add_child(col)

	# Header: title · overall count · Close + Esc
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UITokens.SP_3)
	col.add_child(head)
	var title := Label.new()
	title.text = "FIELD JOURNAL"
	title.theme_type_variation = &"TitleLabel"
	title.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD)
	head.add_child(title)
	_total_label = Label.new()
	_total_label.theme_type_variation = &"StatLabel"
	_total_label.add_theme_color_override("font_color", UITokens.PAPER_300)
	_total_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_total_label)
	close_button = Button.new()
	close_button.text = "Close"
	close_button.icon = UITokens.icon("close")
	close_button.theme_type_variation = &"GhostButton"
	close_button.pressed.connect(close)
	head.add_child(close_button)
	var esc := KeyCap.new()
	esc.label_override = "Esc"
	head.add_child(esc)

	# Planet tabs + progress for the selected planet
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", UITokens.SP_6)
	col.add_child(tab_row)
	tabs = ArchiveTabs.new()
	tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_row.add_child(tabs)
	tabs.set_tabs(PLANETS)
	tabs.tab_selected.connect(_on_tab_selected)
	_planet_meter = SegmentedMeter.new()
	_planet_meter.segment_count = 10
	_planet_meter.accent = UITokens.SIGNAL_GOLD
	_planet_meter.custom_minimum_size = Vector2(160, 14)
	_planet_meter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tab_row.add_child(_planet_meter)
	_planet_count = Label.new()
	_planet_count.theme_type_variation = &"StatLabel"
	tab_row.add_child(_planet_count)

	# Locked-planet notice (words + lock icon)
	_notice_row = HBoxContainer.new()
	_notice_row.add_theme_constant_override("separation", UITokens.SP_2)
	_notice_row.add_child(Badge.make(Badge.Kind.LOCKED, "SURVEY LOCKED"))
	var nt := Label.new()
	nt.text = "Mars opens when the Moon survey is complete. You can still read the slots."
	nt.theme_type_variation = &"CaptionLabel"
	nt.add_theme_color_override("font_color", UITokens.PAPER_300)
	_notice_row.add_child(nt)
	col.add_child(_notice_row)

	# Category filters
	var frow := HBoxContainer.new()
	frow.add_theme_constant_override("separation", UITokens.SP_3)
	col.add_child(frow)
	var fcap := Label.new()
	fcap.text = "CATEGORY"
	fcap.theme_type_variation = &"CaptionLabel"
	fcap.add_theme_color_override("font_color", UITokens.PAPER_300)
	fcap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	frow.add_child(fcap)
	_filter_flow = HFlowContainer.new()
	_filter_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_filter_flow.add_theme_constant_override("h_separation", UITokens.SP_1)
	_filter_flow.add_theme_constant_override("v_separation", UITokens.SP_1)
	frow.add_child(_filter_flow)
	_filter_group = ButtonGroup.new()

	var rule := ColorRect.new()
	rule.color = UITokens.INK_600
	rule.custom_minimum_size = Vector2(0, 1)
	col.add_child(rule)

	# Body: slots (left) | detail (right)
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", UITokens.SP_6)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(body)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.size_flags_stretch_ratio = 1.15
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(_scroll)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", UITokens.SP_2)
	_grid.add_theme_constant_override("v_separation", UITokens.SP_2)
	_scroll.add_child(_grid)

	var detail_card := PanelContainer.new()
	detail_card.theme_type_variation = &"HudPanel"
	detail_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(detail_card)
	_detail_scroll = ScrollContainer.new()
	_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_card.add_child(_detail_scroll)
	_detail_col = VBoxContainer.new()
	_detail_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_col.add_theme_constant_override("separation", UITokens.SP_3)
	_detail_scroll.add_child(_detail_col)


func _rebuild_all() -> void:
	if tabs != null:
		tabs.select(maxi(0, PLANETS.find(planet)), false)
	_refresh_header()
	_rebuild_filters()
	_rebuild_slots()


func _refresh_header() -> void:
	var all_ids: Array = []
	for p in PLANETS:
		all_ids.append_array(_ids_for(p))
	var all := _found_total(all_ids)
	_total_label.text = "%02d / %02d CATALOGUED" % [all.x, all.y]
	for i in PLANETS.size():
		var ft := _found_total(_ids_for(PLANETS[i]))
		var b := tabs.get_button(i)
		if b != null:
			b.text = "%s  %d/%d" % [PLANETS[i], ft.x, ft.y]
	var cur := _found_total(_ids_for(planet))
	_planet_meter.value = float(cur.x) / float(maxi(1, cur.y))
	_planet_count.text = "%02d / %02d" % [cur.x, cur.y]
	var gs = _gs()
	_notice_row.visible = gs != null and not gs.is_planet_unlocked(planet)


func _rebuild_filters() -> void:
	for b in filter_buttons:
		b.queue_free()
	filter_buttons.clear()
	var ids := _ids_for(planet)
	var entries: Array = [["", "All", _found_total(ids)]]
	for c in _categories_for(planet):
		var cat_ids: Array = ids.filter(func(i): return str(_data(i).get("category", "")) == c)
		entries.append([c, c, _found_total(cat_ids)])
	for e in entries:
		var b := Button.new()
		var ft: Vector2i = e[2]
		b.text = ("%s  %d" % [e[1], ft.x]) if (SPOILER_FREE and e[0] != "") else ("%s  %d/%d" % [e[1], ft.x, ft.y])
		b.theme_type_variation = &"TabButton"
		b.toggle_mode = true
		b.button_group = _filter_group
		b.focus_mode = Control.FOCUS_ALL
		b.set_meta("category", e[0])
		b.pressed.connect(_on_filter_pressed.bind(e[0]))
		_filter_flow.add_child(b)
		filter_buttons.append(b)
		if e[0] == category_filter:
			b.set_pressed_no_signal(true)


func _rebuild_slots() -> void:
	for s in slots:
		_grid.remove_child(s)
		s.queue_free()
	slots.clear()
	var ids := _ids_for(planet)
	var n := 0
	var first_visible := ""
	for id in ids:
		n += 1
		var d := _data(id)
		var found := _is_found(id)
		if category_filter != "":
			if str(d.get("category", "")) != category_filter:
				continue
			if SPOILER_FREE and not found:
				continue
		var s := JournalSlot.make(id, n, d, found, _locked_caption(d))
		s.activated.connect(select_artifact)
		s.focused.connect(_on_slot_focused)
		_grid.add_child(s)
		slots.append(s)
		if first_visible == "":
			first_visible = id
	# Keep the selection if it is still listed, otherwise select the first visible slot.
	var keep := false
	for s in slots:
		if s.artifact_id == selected_id:
			keep = true
	if not keep:
		selected_id = first_visible
	for s in slots:
		s.selected = s.artifact_id == selected_id
	_build_detail()


## Locked slots say where to look, never what is there.
func _locked_caption(d: Dictionary) -> String:
	return ("%s · %s" % [str(d.get("location", planet)), _short_stratum(str(d.get("stratigraphic_layer", "")))]).to_upper().trim_suffix(" · ")


## "Upper Loose Regolith (0–8 cm)" -> "Upper Loose Regolith". Keeps the caption on one line.
static func _short_stratum(s: String) -> String:
	var i := s.find("(")
	return (s.substr(0, i) if i > 0 else s).strip_edges()


func _on_tab_selected(index: int) -> void:
	if index < 0 or index >= PLANETS.size():
		return
	show_planet(PLANETS[index])
	_refresh_header()


func _on_filter_pressed(cat: String) -> void:
	category_filter = cat
	_rebuild_slots()


func _on_slot_focused(id: String) -> void:
	if id != selected_id:
		select_artifact(id)


# ── Detail panel ────────────────────────────────────────────────────────────────────────

func _build_detail() -> void:
	for c in _detail_col.get_children():
		_detail_col.remove_child(c)
		c.queue_free()
	detail_name = null
	read_more_button = null
	story_button = null
	if selected_id == "":
		_detail_empty()
		return
	var d := _data(selected_id)
	if _is_found(selected_id):
		_detail_found(selected_id, d)
	else:
		_detail_locked(selected_id, d)


func _position_text(id: String) -> String:
	var ids := _ids_for(planet)
	return "%s · %02d / %02d" % [planet.to_upper(), ids.find(id) + 1, ids.size()]


func _detail_empty() -> void:
	var t := Label.new()
	t.text = "No entries in this view."
	t.theme_type_variation = &"LeadLabel"
	t.add_theme_color_override("font_color", UITokens.PAPER_300)
	_detail_col.add_child(t)
	var h := Label.new()
	h.text = "Choose another category to see more slots."
	h.theme_type_variation = &"CaptionLabel"
	h.add_theme_color_override("font_color", UITokens.PAPER_300)
	_detail_col.add_child(h)


func _detail_found(id: String, d: Dictionary) -> void:
	var head := HBoxContainer.new()
	_detail_col.add_child(head)
	var cat := _caption(str(d.get("category", "")).to_upper(), UITokens.SIGNAL_GOLD)
	cat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(cat)
	var pos := Label.new()
	pos.text = _position_text(id)
	pos.theme_type_variation = &"StatLabel"
	pos.add_theme_color_override("font_color", UITokens.PAPER_300)
	head.add_child(pos)

	detail_name = Label.new()
	detail_name.text = str(d.get("name", id))
	detail_name.theme_type_variation = &"DisplayLabel"
	detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_col.add_child(detail_name)

	var badges := HBoxContainer.new()
	badges.add_theme_constant_override("separation", UITokens.SP_2)
	badges.add_child(Badge.make(Badge.Kind.ARCHIVE))
	badges.add_child(Badge.make(Badge.Kind.OK))
	_detail_col.add_child(badges)

	# Data row: mission | year | planet
	var data_row := HBoxContainer.new()
	data_row.add_theme_constant_override("separation", UITokens.SP_6)
	_detail_col.add_child(data_row)
	_cell(data_row, "MISSION", str(d.get("mission", "—")))
	_cell(data_row, "YEAR", _format_year(d.get("year", "")))
	_cell(data_row, "LOCATION", str(d.get("location", "—")))

	_rule_into(_detail_col)

	# Key facts (3): purpose, status, size
	_fact("PURPOSE", str(d.get("purpose", "")))
	_fact("STATUS", str(d.get("status", "")))
	var size_parts: PackedStringArray = []
	if str(d.get("dimensions_cm", "")) != "":
		size_parts.append(str(d["dimensions_cm"]))
	if d.has("mass_kg"):
		size_parts.append("%s kg" % _trim_num(d["mass_kg"]))
	_fact("SIZE", " · ".join(size_parts))

	# Progressive disclosure: narrative + sources behind READ MORE
	var more := VBoxContainer.new()
	more.add_theme_constant_override("separation", UITokens.SP_2)
	more.visible = _expanded
	more.name = "More"
	var hist := str(d.get("history", ""))
	if hist != "":
		var hc := _caption("HISTORICAL ACCOUNT", UITokens.PAPER_300)
		more.add_child(hc)
		more.add_child(_body(hist))
	var src: Array = d.get("sources", [])
	if not src.is_empty():
		more.add_child(_caption("SOURCES", UITokens.PAPER_300))
		more.add_child(_body("; ".join(PackedStringArray(src))))

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", UITokens.SP_3)
	_detail_col.add_child(actions)
	if hist != "" or not src.is_empty():
		read_more_button = Button.new()
		read_more_button.theme_type_variation = &"GhostButton"
		read_more_button.toggle_mode = false
		read_more_button.pressed.connect(_toggle_more.bind(more))
		actions.add_child(read_more_button)
		_sync_more_button(more)
	if has_story(id):
		story_button = Button.new()
		story_button.text = "Watch story"
		story_button.icon = UITokens.icon("play")
		story_button.theme_type_variation = &"PrimaryButton"
		story_button.pressed.connect(_on_story_pressed.bind(id))
		actions.add_child(story_button)
	_detail_col.add_child(more)


func _detail_locked(id: String, d: Dictionary) -> void:
	var head := HBoxContainer.new()
	_detail_col.add_child(head)
	var cat := _caption("UNIDENTIFIED", UITokens.PAPER_300)
	cat.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(cat)
	var pos := Label.new()
	pos.text = _position_text(id)
	pos.theme_type_variation = &"StatLabel"
	pos.add_theme_color_override("font_color", UITokens.PAPER_300)
	head.add_child(pos)

	detail_name = Label.new()
	detail_name.text = "Subsurface anomaly"
	detail_name.theme_type_variation = &"DisplayLabel"
	detail_name.add_theme_color_override("font_color", UITokens.PAPER_300)
	detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_col.add_child(detail_name)

	_detail_col.add_child(Badge.make(Badge.Kind.LOCKED, "NOT CATALOGUED"))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UITokens.SP_6)
	_detail_col.add_child(row)
	_cell(row, "LOCATION", str(d.get("location", planet)))
	var layer := str(d.get("stratigraphic_layer", ""))
	if layer != "":
		_cell(row, "STRATUM", _short_stratum(layer))

	_rule_into(_detail_col)
	_fact("HOW TO FIND IT", "Follow the survey scanner signal. Excavate the anomaly, clean it, and its record is added to this journal.")
	_fact("WHAT YOU KNOW", "A buried object of unknown type. Its name and category stay sealed until it is catalogued.")


func _toggle_more(more: Control) -> void:
	_expanded = not _expanded
	more.visible = _expanded
	_sync_more_button(more)


func _sync_more_button(_more: Control) -> void:
	if read_more_button != null:
		read_more_button.text = "Show less" if _expanded else "Read more"


func _on_story_pressed(id: String) -> void:
	close()
	story_requested.emit(id)


# ── Small builders (token-styled) ───────────────────────────────────────────────────────

func _caption(t: String, c: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.theme_type_variation = &"CaptionLabel"
	l.add_theme_color_override("font_color", c)
	return l


func _body(t: String) -> Label:
	var l := Label.new()
	l.text = t
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_color_override("font_color", UITokens.PAPER_100)
	return l


func _fact(head: String, body: String) -> void:
	if body.strip_edges() == "":
		return
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.add_child(_caption(head, UITokens.PAPER_300))
	v.add_child(_body(body))
	_detail_col.add_child(v)


func _cell(parent: Control, head: String, value: String) -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.add_child(_caption(head, UITokens.PAPER_300))
	var l := Label.new()
	l.text = value
	l.theme_type_variation = &"StatLabel"
	l.add_theme_color_override("font_color", UITokens.PAPER_100)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(l)
	parent.add_child(v)


func _rule_into(parent: Control) -> void:
	var r := ColorRect.new()
	r.color = UITokens.INK_600
	r.custom_minimum_size = Vector2(0, 1)
	parent.add_child(r)


## 1971, 1971.0 and "1971" all print as 1971 (audit bug B3).
static func _format_year(v) -> String:
	if v is float or v is int:
		return str(int(v))
	return str(v)


static func _trim_num(v) -> String:
	if v is float and v == floorf(v):
		return str(int(v))
	return str(v)
