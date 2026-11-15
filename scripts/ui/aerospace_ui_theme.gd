class_name AerospaceTheme
extends RefCounted

# Echoes Beyond Earth - Unified Aerospace Telemetry Design System
# Color Palette:
# - Background: Near-black (#05090D)
# - Primary accent: Electric cyan (#00E5FF)
# - Secondary accent: Turquoise (#00BFA5)
# - Warning: Amber/orange (#FF9D32)
# - Critical: Muted red (#FF4545)
# - Positive status: Green (#39E58C)
# - Primary text: Cool white (#E5F2F5)
# - Secondary text: Muted blue-grey (#77909D)

const COLOR_BG_DARK = Color(0.0196, 0.0353, 0.0510, 0.88)
const COLOR_BG_SOLID = Color(0.0196, 0.0353, 0.0510, 1.0)
const COLOR_CYAN = Color(0.0, 0.898, 1.0, 1.0)
const COLOR_CYAN_DIM = Color(0.0, 0.898, 1.0, 0.45)
const COLOR_CYAN_FAINT = Color(0.0, 0.898, 1.0, 0.15)
const COLOR_TURQUOISE = Color(0.0, 0.749, 0.647, 1.0)
const COLOR_TURQUOISE_DIM = Color(0.0, 0.749, 0.647, 0.45)
const COLOR_AMBER = Color(1.0, 0.616, 0.196, 1.0)
const COLOR_AMBER_DIM = Color(1.0, 0.616, 0.196, 0.45)
const COLOR_CRITICAL = Color(1.0, 0.271, 0.271, 1.0)
const COLOR_STATUS_GREEN = Color(0.224, 0.898, 0.549, 1.0)
const COLOR_TEXT_PRIMARY = Color(0.898, 0.949, 0.961, 1.0)
const COLOR_TEXT_SECONDARY = Color(0.467, 0.565, 0.616, 1.0)

# Creates a StyleBoxTexture for aerospace glass panels
static func create_glass_panel_style(texture_path: String = "res://textures/ui/sci_fi_glass_panel.png", pad: int = 14) -> StyleBoxTexture:
	var sb = StyleBoxTexture.new()
	var tex = load(texture_path)
	if tex:
		sb.texture = tex
		sb.texture_margin_left = 16
		sb.texture_margin_top = 16
		sb.texture_margin_right = 16
		sb.texture_margin_bottom = 16
		sb.content_margin_left = pad
		sb.content_margin_top = pad
		sb.content_margin_right = pad
		sb.content_margin_bottom = pad
	return sb

# Creates flat technical sub-panel style with thin cyan border and chamfered aesthetics
static func create_technical_badge_style(border_col: Color = COLOR_CYAN, bg_col: Color = COLOR_BG_DARK) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = border_col
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_right = 4
	sb.corner_radius_bottom_left = 4
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb
