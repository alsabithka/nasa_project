class_name SectionHeader
extends Control

## Echoes Beyond Earth — SectionHeader Component
## A left-aligned uppercase label with a 1px ink-600 rule below it.
## Usage: set .title to the section name.

@export var title: String = "SECTION" : set = set_title

var _label: Label
var _rule: ColorRect

func _ready() -> void:
	custom_minimum_size.y = 32
	size_flags_horizontal = SIZE_EXPAND_FILL
	mouse_filter = MOUSE_FILTER_IGNORE
	_build()

func set_title(v: String) -> void:
	title = v
	if _label:
		_label.text = v.to_upper()

func _build() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(PRESET_FULL_RECT)
	vb.mouse_filter = MOUSE_FILTER_IGNORE
	vb.add_theme_constant_override("separation", 4)
	add_child(vb)

	_label = Label.new()
	_label.text = title.to_upper()
	_label.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
	_label.add_theme_color_override("font_color", UITokens.PAPER_300)
	_label.mouse_filter = MOUSE_FILTER_IGNORE
	vb.add_child(_label)

	_rule = ColorRect.new()
	_rule.custom_minimum_size = Vector2(0, 1)
	_rule.color = UITokens.INK_600
	_rule.size_flags_horizontal = SIZE_EXPAND_FILL
	_rule.mouse_filter = MOUSE_FILTER_IGNORE
	vb.add_child(_rule)
