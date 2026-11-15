class_name ArchiveCard
extends PanelContainer

## Echoes Beyond Earth — ArchiveCard Component
## A "Declassified Archive" styled panel: ink-800 bg, ink-600 1px border,
## 0 corner radius, optional gold 4,4 hard-offset shadow.
## Drop into any scene and add children; the card handles its own styling.

@export var show_offset_shadow: bool = false : set = set_shadow

func _ready() -> void:
	_apply_style()

func set_shadow(val: bool) -> void:
	show_offset_shadow = val
	if is_inside_tree():
		_apply_style()

func _apply_style() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color     = UITokens.INK_800
	sb.border_color = UITokens.INK_600
	sb.set_border_width_all(UITokens.BORDER_PANEL)
	sb.set_corner_radius_all(UITokens.RADIUS_PANEL)
	sb.content_margin_left   = float(UITokens.SP_4)
	sb.content_margin_top    = float(UITokens.SP_3)
	sb.content_margin_right  = float(UITokens.SP_4)
	sb.content_margin_bottom = float(UITokens.SP_3)

	if show_offset_shadow:
		sb.shadow_color  = UITokens.INK_900
		sb.shadow_size   = 1
		sb.shadow_offset = Vector2(4, 4)

	add_theme_stylebox_override("panel", sb)
