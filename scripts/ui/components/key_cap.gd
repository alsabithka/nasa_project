class_name KeyCap
extends PanelContainer

## Echoes Beyond Earth — KeyCap Component
## Shows a keyboard/gamepad hint that reads from the InputMap.
## Usage: set action_name in the inspector or via code.
##   $KeyCap.action_name = "interact"
##   $KeyCap.label_override = "E"  # bypass InputMap lookup
##
## Renders as:  [ E ]  in PAPER_100 on INK_700 panel.

@export var action_name: String = "interact" : set = set_action
@export var label_override: String = "" : set = set_label_override

@onready var _key_label: Label = $Label

func _ready() -> void:
	_apply_style()
	refresh()

func set_action(val: String) -> void:
	action_name = val
	if is_inside_tree():
		refresh()

func set_label_override(val: String) -> void:
	label_override = val
	if is_inside_tree():
		refresh()

## Re-read the InputMap and update the displayed key.
func refresh() -> void:
	if not _key_label:
		return
	var display := label_override
	if display.is_empty():
		display = _get_action_key(action_name)
	_key_label.text = "[ %s ]" % display.to_upper()

## Look up the first keyboard event bound to an action.
func _get_action_key(act: String) -> String:
	if not InputMap.has_action(act):
		return act.to_upper()
	for event in InputMap.action_get_events(act):
		if event is InputEventKey:
			var ev := event as InputEventKey
			# keycode first, physical_keycode fallback
			var kc := ev.keycode if ev.keycode != KEY_NONE else ev.physical_keycode
			if kc != KEY_NONE:
				return OS.get_keycode_string(kc)
	# No keyboard binding found — return action name as fallback
	return act.split("_").map(func(w): return w[0].to_upper() + w.substr(1)).reduce(func(a,b): return a+" "+b)

func _apply_style() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color      = UITokens.INK_700
	sb.border_color  = UITokens.INK_600
	sb.set_border_width_all(UITokens.BORDER_CONTROL)
	sb.set_corner_radius_all(UITokens.RADIUS_CONTROL)
	sb.content_margin_left   = float(UITokens.SP_2)
	sb.content_margin_right  = float(UITokens.SP_2)
	sb.content_margin_top    = 2.0
	sb.content_margin_bottom = 2.0
	add_theme_stylebox_override("panel", sb)

	if _key_label:
		_key_label.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
		_key_label.add_theme_color_override("font_color", UITokens.PAPER_300)
