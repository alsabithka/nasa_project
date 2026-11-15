class_name HudPanel
extends PanelContainer

## Echoes Beyond Earth — HudPanel Component
## Translucent, instrument-register panel for the in-world HUD overlay.
## Lighter than ArchiveCard; lets the 3D scene bleed through slightly.

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_apply_style()

func _apply_style() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color     = Color(UITokens.INK_900.r, UITokens.INK_900.g, UITokens.INK_900.b, 0.82)
	sb.border_color = Color(UITokens.INK_600.r, UITokens.INK_600.g, UITokens.INK_600.b, 0.6)
	sb.set_border_width_all(UITokens.BORDER_PANEL)
	sb.set_corner_radius_all(UITokens.RADIUS_PANEL)
	sb.content_margin_left   = float(UITokens.SP_3)
	sb.content_margin_top    = float(UITokens.SP_2)
	sb.content_margin_right  = float(UITokens.SP_3)
	sb.content_margin_bottom = float(UITokens.SP_2)
	add_theme_stylebox_override("panel", sb)
