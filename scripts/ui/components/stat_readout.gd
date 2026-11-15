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
## True for invented / simulated values — shows a SIM badge so players can tell simulation from fact.
@export var simulated: bool = false : set = set_simulated

var _title_label: Label
var _value_label: Label
var _sim_badge: Badge

func _ready() -> void:
	add_theme_constant_override("separation", 2)
	mouse_filter = MOUSE_FILTER_IGNORE

	_title_label = Label.new()
	_title_label.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(_title_label)

	var value_row := HBoxContainer.new()
	value_row.add_theme_constant_override("separation", UITokens.SP_2)
	value_row.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(value_row)
	_value_label = Label.new()
	_value_label.theme_type_variation = &"StatLabel"   # IBM Plex Mono — live numerals
	_value_label.mouse_filter = MOUSE_FILTER_IGNORE
	value_row.add_child(_value_label)
	_sim_badge = Badge.make(Badge.Kind.SIM)
	_sim_badge.visible = simulated
	value_row.add_child(_sim_badge)

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
func set_simulated(v: bool) -> void:
	simulated = v
	if _sim_badge:
		_sim_badge.visible = v
func set_accent(c: Color) -> void:
	accent_color = c
	if _value_label:
		_value_label.add_theme_color_override("font_color", c)

func _refresh_all() -> void:
	_title_label.text = title
	_title_label.theme_type_variation = &"CaptionLabel"

	_value_label.text = ("%s %s" % [value, unit]).strip_edges()
	_value_label.add_theme_color_override("font_color", accent_color)

## Convenience setter used by HUD to update live values.
func update(new_value: String, new_unit: String = "") -> void:
	set_value(new_value)
	if not new_unit.is_empty():
		set_unit(new_unit)
