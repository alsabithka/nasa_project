class_name SegmentedMeter
extends Control

## Echoes Beyond Earth — SegmentedMeter Component
## A horizontal segmented bar (like a signal strength or fuel gauge).
## Segments light up left-to-right in ONE accent colour (house rule: one accent per component).
## Optionally flips to `warn_color` below `warn_below` (the segment COUNT still carries the
## value, so the meter never relies on colour alone).
##
## Usage:
##   $Meter.segment_count = 8
##   $Meter.value = 0.6        # 0.0–1.0
##   $Meter.accent = UITokens.SIGNAL_CYAN
##   $Meter.warn_below = 0.2   # optional

@export var segment_count: int = 8 : set = set_segments
@export_range(0.0, 1.0) var value: float = 0.5 : set = set_value
@export var accent: Color = Color(0.502, 0.8, 1.0) : set = set_accent   # SIGNAL_CYAN
@export var warn_color: Color = Color(1.0, 0.353, 0.302)                 # SIGNAL_RED
@export_range(0.0, 1.0) var warn_below: float = 0.0
@export var gap_px: int = 2
## Vertical meters fill bottom-to-top (merge P6: dig depth gauge).
@export var vertical: bool = false : set = set_vertical

var _rects: Array[ColorRect] = []

func _ready() -> void:
	if vertical:
		custom_minimum_size = Vector2(14, maxf(120.0, custom_minimum_size.y))
	else:
		custom_minimum_size = Vector2(120, 14)
	mouse_filter = MOUSE_FILTER_IGNORE
	_build_segments()

func set_segments(n: int) -> void:
	segment_count = max(1, n)
	if is_inside_tree():
		_build_segments()

func set_vertical(v: bool) -> void:
	vertical = v
	if is_inside_tree():
		_build_segments()

func set_value(v: float) -> void:
	value = clampf(v, 0.0, 1.0)
	if is_inside_tree():
		_refresh_colors()

func _build_segments() -> void:
	for c in get_children():
		c.queue_free()
	_rects.clear()

	var container := BoxContainer.new()
	container.vertical = vertical
	container.set_anchors_preset(PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", gap_px)
	container.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(container)

	for i in range(segment_count):
		var r := ColorRect.new()
		r.size_flags_horizontal = SIZE_EXPAND_FILL
		r.size_flags_vertical = SIZE_EXPAND_FILL
		r.mouse_filter = MOUSE_FILTER_IGNORE
		container.add_child(r)
		_rects.append(r)

	_refresh_colors()

func set_accent(c: Color) -> void:
	accent = c
	if is_inside_tree():
		_refresh_colors()

func _refresh_colors() -> void:
	var lit := int(ceil(value * segment_count))
	var lit_color := warn_color if (warn_below > 0.0 and value < warn_below) else accent
	for i in range(_rects.size()):
		# vertical meters fill from the bottom (last child), horizontal from the left (first child)
		var rank := (_rects.size() - 1 - i) if vertical else i
		_rects[i].color = lit_color if rank < lit else UITokens.INK_700
