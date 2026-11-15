class_name StatReadout
extends VBoxContainer

## Echoes Beyond Earth — StatReadout Component
## A telemetry-style label pair: TITLE (caption) + VALUE (body, monospaced feel).
## Usage:
##   $StatReadout.title = "HEART RATE"
##   $StatReadout.value = "82"
##   $StatReadout.unit  = "BPM"
##   $StatReadout.accent_color = UITokens.SIGNAL_GOLD

@export var title: String = "STAT" : set = set_title
@export var value: String = "--"   : set = set_value
@export var unit: String  = ""     : set = set_unit
@export var accent_color: Color = Color(0.502, 0.8, 1.0) : set = set_accent  # SIGNAL_CYAN default

var _title_label: Label
var _value_label: Label

func _ready() -> void:
	add_theme_constant_override("separation", 2)
	mouse_filter = MOUSE_FILTER_IGNORE

	_title_label = Label.new()
	_title_label.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_title_label)

	_value_label = Label.new()
	_value_label.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_value_label)

	_refresh_all()

func set_title(v: String) -> void:
	title = v
	if _title_label:
		_title_label.text = v
func set_value(v: String) -> void:
	value = v
	if _value_label:
		_value_label.text = ("%s %s" % [v, unit]).strip_edges()
func set_unit(v: String) -> void:
	unit = v
	if _value_label:
		_value_label.text = ("%s %s" % [value, v]).strip_edges()
func set_accent(c: Color) -> void:
	accent_color = c
	if _value_label:
		_value_label.add_theme_color_override("font_color", c)

func _refresh_all() -> void:
	_title_label.text = title
	_title_label.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
	_title_label.add_theme_color_override("font_color", UITokens.PAPER_500)

	_value_label.text = ("%s %s" % [value, unit]).strip_edges()
	_value_label.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
	_value_label.add_theme_color_override("font_color", accent_color)

## Convenience setter used by HUD to update live values.
func update(new_value: String, new_unit: String = "") -> void:
	set_value(new_value)
	if not new_unit.is_empty():
		set_unit(new_unit)
