class_name JournalSlot
extends PanelContainer

## Echoes Beyond Earth — JournalSlot Component (Phase 6)
## One numbered slot of the field journal: [silhouette] NN / name / caption.
##
## States (never colour alone — each one changes shape and words):
##   CATALOGUED  solid category silhouette, artifact name, category caption, gold number
##   LOCKED      dashed square + lock icon, "Subsurface anomaly", "NOT CATALOGUED"
## A locked slot deliberately shows NO category and NO name: the scanner mystery stays intact.
##
## Keyboard / gamepad: focusable, ui_accept activates, focus also reports `focused` so the
## detail panel can follow the cursor. Selected = gold 2 px border + INK_700 fill.

signal activated(artifact_id: String)
signal focused(artifact_id: String)

var artifact_id: String = ""
var recovered: bool = false
var selected: bool = false : set = set_selected

var _number_label: Label
var _title_label: Label
var _caption_label: Label
var _sil: Silhouette
var _hover := false
var _focus := false


## Maps an artifact `category` string to a Bauhaus shape name. Pure function (unit-testable).
static func shape_for(category: String) -> String:
	var c := category.to_lower()
	if c.contains("natural"):
		return "circle"
	if c.contains("scientific"):
		return "triangle"
	if c.contains("probe"):
		return "ring"
	if c.contains("spacecraft"):
		return "diamond"
	return "square"   # mission remnants and anything unknown


## Builds a slot. `number` is the 1-based position inside the planet (same numbering as the
## Catalogue Entry: MOON · 03 / 07).
static func make(id: String, number: int, data: Dictionary, is_recovered: bool, locked_caption: String) -> JournalSlot:
	var s := JournalSlot.new()
	s.artifact_id = id
	s.recovered = is_recovered
	s._pending = {
		"number": number,
		"name": str(data.get("name", id)),
		"category": str(data.get("category", "")),
		"locked_caption": locked_caption,
	}
	return s


var _pending: Dictionary = {}


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(232, 64)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UITokens.SP_3)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)

	_sil = Silhouette.new()
	_sil.custom_minimum_size = Vector2(44, 44)
	_sil.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_sil)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)

	_number_label = Label.new()
	_number_label.theme_type_variation = &"StatLabel"   # IBM Plex Mono numerals
	_number_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_number_label)

	_title_label = Label.new()
	_title_label.theme_type_variation = &"LeadLabel"
	_title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_title_label.clip_text = true
	_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_title_label)

	_caption_label = Label.new()
	_caption_label.theme_type_variation = &"CaptionLabel"
	_caption_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_caption_label.clip_text = true
	_caption_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_caption_label)

	mouse_entered.connect(func() -> void: _hover = true; _style())
	mouse_exited.connect(func() -> void: _hover = false; _style())
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(func() -> void: _focus = false; _style())
	_refresh()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		grab_focus()
		activated.emit(artifact_id)
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		activated.emit(artifact_id)
		accept_event()


func set_selected(v: bool) -> void:
	selected = v
	_style()


func _on_focus_entered() -> void:
	_focus = true
	_style()
	focused.emit(artifact_id)


func _refresh() -> void:
	if _number_label == null:
		return
	var n: int = int(_pending.get("number", 0))
	_number_label.text = "%02d" % n
	_number_label.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD if recovered else UITokens.PAPER_500)
	if recovered:
		_title_label.text = str(_pending.get("name", ""))
		_title_label.add_theme_color_override("font_color", UITokens.PAPER_100)
		_caption_label.text = str(_pending.get("category", "")).to_upper()
		_caption_label.add_theme_color_override("font_color", UITokens.PAPER_300)
	else:
		_title_label.text = "Subsurface anomaly"
		_title_label.add_theme_color_override("font_color", UITokens.PAPER_500)
		_caption_label.text = str(_pending.get("locked_caption", "NOT CATALOGUED"))
		_caption_label.add_theme_color_override("font_color", UITokens.PAPER_500)
	_sil.shape = shape_for(str(_pending.get("category", ""))) if recovered else "locked"
	_sil.queue_redraw()
	_style()


func _style() -> void:
	var on := selected or _focus
	var sb := StyleBoxFlat.new()
	sb.bg_color = UITokens.INK_700 if (_hover or selected) else UITokens.INK_800
	# Control borders must reach 3:1: PAPER_500 for idle, gold for selected / focused.
	sb.border_color = UITokens.SIGNAL_GOLD if on else UITokens.PAPER_500
	sb.set_border_width_all(UITokens.BORDER_CONTROL if on else UITokens.BORDER_PANEL)
	sb.set_corner_radius_all(UITokens.RADIUS_PANEL)
	sb.content_margin_left = 10.0
	sb.content_margin_right = 10.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0
	add_theme_stylebox_override("panel", sb)


## Drawn silhouette: Bauhaus geometry per category, dashed square + lock when locked.
class Silhouette extends Control:
	var shape: String = "locked"

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := minf(size.x, size.y) * 0.5 - 4.0
		var c := size * 0.5
		if shape == "locked":
			var a := Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0)
			var col := UITokens.PAPER_500
			var tl := a.position
			var tr := Vector2(a.end.x, a.position.y)
			var br := a.end
			var bl := Vector2(a.position.x, a.end.y)
			draw_dashed_line(tl, tr, col, 2.0, 5.0)
			draw_dashed_line(tr, br, col, 2.0, 5.0)
			draw_dashed_line(br, bl, col, 2.0, 5.0)
			draw_dashed_line(bl, tl, col, 2.0, 5.0)
			var lock := UITokens.icon("lock")
			if lock != null:
				var s := 18.0
				draw_texture_rect(lock, Rect2(c - Vector2(s, s) * 0.5, Vector2(s, s)), false, UITokens.PAPER_500)
			return
		var fill := UITokens.PAPER_300
		var line := UITokens.PAPER_100
		match shape:
			"circle":
				draw_circle(c, r, fill)
				draw_arc(c, r, 0.0, TAU, 32, line, 2.0)
			"triangle":
				var tri := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, r * 0.8), c + Vector2(-r, r * 0.8)])
				draw_colored_polygon(tri, fill)
				draw_polyline(tri + PackedVector2Array([tri[0]]), line, 2.0)
			"diamond":
				var d := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])
				draw_colored_polygon(d, fill)
				draw_polyline(d + PackedVector2Array([d[0]]), line, 2.0)
			"ring":
				draw_arc(c, r, 0.0, TAU, 32, fill, 5.0)
				draw_circle(c, r * 0.28, line)
			_:
				var q := Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0)
				draw_rect(q, fill, true)
				draw_rect(q, line, false, 2.0)
		# Gold registration mark: the entry is in the archive (shape + colour).
		draw_rect(Rect2(Vector2(size.x - 9.0, 1.0), Vector2(8.0, 8.0)), UITokens.SIGNAL_GOLD, true)
