class_name ChapterButton
extends Button

## Echoes Beyond Earth — ChapterButton
## One planet = one chapter: icon, name, progress meter, "3 / 7" in mono, state.
## Locked chapters are disabled AND say why (never a clickable contradiction).
##   var b := ChapterButton.new()
##   b.setup("MOON", "moon", found, total)            # unlocked
##   b.setup("MARS", "mars", 0, 7, "Locked — catalogue every Moon artifact first")

var _title: String = ""
var _icon_name: String = ""
var _found: int = 0
var _total: int = 0
var _lock_reason: String = ""


func setup(title_text: String, icon_name: String, found: int, total: int, lock_reason: String = "") -> void:
	_title = title_text
	_icon_name = icon_name
	_found = found
	_total = total
	_lock_reason = lock_reason
	disabled = lock_reason != ""
	if is_inside_tree():
		_rebuild()


func _ready() -> void:
	custom_minimum_size = Vector2(440, 72)
	focus_mode = Control.FOCUS_ALL
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	_apply_styles()
	_rebuild()


func _box(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(UITokens.RADIUS_PANEL)
	sb.content_margin_left = float(UITokens.SP_4)
	sb.content_margin_right = float(UITokens.SP_4)
	sb.content_margin_top = float(UITokens.SP_3)
	sb.content_margin_bottom = float(UITokens.SP_3)
	return sb


func _apply_styles() -> void:
	add_theme_stylebox_override("normal", _box(UITokens.INK_800, UITokens.PAPER_500, 1))
	add_theme_stylebox_override("hover", _box(UITokens.INK_700, UITokens.PAPER_300, 1))
	add_theme_stylebox_override("pressed", _box(UITokens.INK_700, UITokens.SIGNAL_GOLD, 2))
	add_theme_stylebox_override("focus", _box(UITokens.INK_700, UITokens.SIGNAL_GOLD, 2))
	add_theme_stylebox_override("disabled", _box(UITokens.INK_900, UITokens.INK_600, 1))


func _rebuild() -> void:
	for c in get_children():
		c.queue_free()
	var locked: bool = _lock_reason != ""
	var accent: Color = UITokens.PAPER_500 if locked else UITokens.SIGNAL_GOLD

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", UITokens.SP_4)
	margin.add_theme_constant_override("margin_right", UITokens.SP_4)
	margin.add_theme_constant_override("margin_top", UITokens.SP_3)
	margin.add_theme_constant_override("margin_bottom", UITokens.SP_3)
	add_child(margin)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", UITokens.SP_4)
	margin.add_child(row)

	row.add_child(UITokens.make_icon("lock" if locked else _icon_name, accent, 28))

	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", UITokens.SP_1)
	row.add_child(col)

	var name_lbl := Label.new()
	name_lbl.text = _title
	name_lbl.theme_type_variation = &"LeadLabel"
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_lbl.add_theme_color_override("font_color", UITokens.PAPER_500 if locked else UITokens.PAPER_100)
	col.add_child(name_lbl)

	if locked:
		var why := Label.new()
		why.text = _lock_reason
		why.theme_type_variation = &"CaptionLabel"
		why.mouse_filter = Control.MOUSE_FILTER_IGNORE
		why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(why)
	else:
		var meter := SegmentedMeter.new()
		meter.segment_count = maxi(1, _total)
		meter.value = float(_found) / float(maxi(1, _total))
		meter.accent = UITokens.SIGNAL_GOLD
		meter.custom_minimum_size = Vector2(0, 10)
		meter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		col.add_child(meter)

	var count := Label.new()
	count.theme_type_variation = &"StatLabel"
	count.mouse_filter = Control.MOUSE_FILTER_IGNORE
	count.text = "— / —" if locked else "%d / %d" % [_found, _total]
	count.add_theme_color_override("font_color", UITokens.PAPER_500 if locked else UITokens.SIGNAL_GOLD)
	row.add_child(count)
