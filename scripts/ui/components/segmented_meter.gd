class_name SegmentedMeter
extends Control

## Echoes Beyond Earth — SegmentedMeter Component
## A horizontal segmented bar (like a signal strength or fuel gauge).
## Segments light up left-to-right with an accent colour.
##
## Usage:
##   $Meter.segment_count = 8
##   $Meter.value = 0.6        # 0.0–1.0
##   $Meter.low_color  = UITokens.SIGNAL_RED
##   $Meter.mid_color  = UITokens.SIGNAL_GOLD
##   $Meter.high_color = UITokens.SIGNAL_GREEN

@export var segment_count: int = 8 : set = set_segments
@export_range(0.0, 1.0) var value: float = 0.5 : set = set_value
@export var low_color:  Color = Color(1.0, 0.353, 0.302)   # SIGNAL_RED
@export var mid_color:  Color = Color(0.98, 0.78, 0.2)      # SIGNAL_GOLD
@export var high_color: Color = Color(0.502, 0.8, 1.0)      # SIGNAL_CYAN
@export var gap_px: int = 2

var _rects: Array[ColorRect] = []

func _ready() -> void:
	custom_minimum_size = Vector2(120, 14)
	mouse_filter = MOUSE_FILTER_IGNORE
	_build_segments()

func set_segments(n: int) -> void:
	segment_count = max(1, n)
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

	var container := HBoxContainer.new()
	container.set_anchors_preset(PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", gap_px)
	container.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(container)

	for i in range(segment_count):
		var r := ColorRect.new()
		r.size_flags_horizontal = SIZE_EXPAND_FILL
		r.mouse_filter = MOUSE_FILTER_IGNORE
		container.add_child(r)
		_rects.append(r)

	_refresh_colors()

func _refresh_colors() -> void:
	var lit := int(ceil(value * segment_count))
	for i in range(_rects.size()):
		if i < lit:
			# Colour interpolation: low→mid at 50%, mid→high at 100%
			var t := float(i + 1) / float(segment_count)
			var col: Color
			if t < 0.5:
				col = low_color.lerp(mid_color, t * 2.0)
			else:
				col = mid_color.lerp(high_color, (t - 0.5) * 2.0)
			_rects[i].color = col
		else:
			_rects[i].color = UITokens.INK_700
