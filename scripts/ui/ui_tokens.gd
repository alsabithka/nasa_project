## UITokens — Design token constants for Echoes Beyond Earth UI/UX system.
## Usage: UITokens.INK_900, UITokens.SP_4, etc.
## Do NOT add this to Autoloads; reference as a static class directly.
class_name UITokens
extends RefCounted

## ── PALETTE ──────────────────────────────────────────────────
# Ink surfaces (dark backgrounds, panels)
static var INK_900 := Color("#07090D")
static var INK_800 := Color("#0D1117")
static var INK_700 := Color("#151B24")
static var INK_600 := Color("#2A3442")

# Paper / text (light foregrounds)
static var PAPER_100 := Color("#E8EAED")
static var PAPER_300 := Color("#A3ACB9")
static var PAPER_500 := Color("#7C8797")

# Signal accents (status, highlights, data readouts)
static var SIGNAL_GOLD  := Color("#FAC733")
static var SIGNAL_CYAN  := Color("#80CCFF")
static var SIGNAL_RED   := Color("#FF5A4D")
static var SIGNAL_GREEN := Color("#5FE08A")

## ── TYPOGRAPHY ───────────────────────────────────────────────
## Font sizes in pixels. Use IBM Plex Sans (UI) / IBM Plex Mono (numerals).
static var TEXT_CAPTION := 12
static var TEXT_BODY    := 14
static var TEXT_LEAD    := 16
static var TEXT_TITLE   := 20
static var TEXT_DISPLAY := 28
static var TEXT_HERO    := 40

## ── SPACING (4-pt scale) ─────────────────────────────────────
static var SP_1  := 4
static var SP_2  := 8
static var SP_3  := 12
static var SP_4  := 16
static var SP_6  := 24
static var SP_8  := 32
static var SP_12 := 48

## ── SHAPE ────────────────────────────────────────────────────
## Corner radii (px). Brutalist — panels are sharp, controls barely rounded.
static var RADIUS_PANEL   := 0
static var RADIUS_CONTROL := 2

## Border widths (px).
static var BORDER_PANEL   := 1
static var BORDER_CONTROL := 2
static var BORDER_FOCUS   := 2

## ── MOTION (seconds) ─────────────────────────────────────────
## Pass directly to Tween.tween_property() duration parameter.
static var DURATION_INSTANT   := 0.0
static var DURATION_FAST      := 0.12
static var DURATION_BASE      := 0.20
static var DURATION_SLOW      := 0.40
static var DURATION_CINEMATIC := 0.80

## ── CANVAS LAYERS ────────────────────────────────────────────
## Assign to CanvasLayer.layer. Higher = rendered on top.
static var LAYER_WORLD_HUD := 0
static var LAYER_TELEMETRY := 5
static var LAYER_OVERLAYS  := 10
static var LAYER_MODALS    := 20
static var LAYER_CINEMA    := 30
static var LAYER_SYSTEM    := 40
static var LAYER_DEBUG     := 50

## ── ASSET HELPERS (Phase 2) ──────────────────────────────────
const ICON_DIR := "res://assets/ui/icons/"
const THEME_PATH := "res://ui/theme/ebe_theme.tres"

static var _icon_cache: Dictionary = {}

## Returns the SVG icon texture for `icon_name` (file name without extension), or null.
## Icons are white — tint with modulate/self_modulate (e.g. UITokens.SIGNAL_GOLD).
static func icon(icon_name: String) -> Texture2D:
	if _icon_cache.has(icon_name):
		return _icon_cache[icon_name]
	var path := ICON_DIR + icon_name + ".svg"
	var tex: Texture2D = load(path) if ResourceLoader.exists(path) else null
	if tex == null:
		push_warning("UITokens.icon: missing icon '%s'" % icon_name)
	_icon_cache[icon_name] = tex
	return tex

## Loads the shared Theme (apply per scene root: `theme = UITokens.theme()`).
static func theme() -> Theme:
	return load(THEME_PATH) as Theme

## Creates a TextureRect showing a tinted icon at a fixed size.
static func make_icon(icon_name: String, tint: Color = Color(0.91, 0.918, 0.929), px: int = 16) -> TextureRect:
	var r := TextureRect.new()
	r.texture = icon(icon_name)
	r.modulate = tint
	r.custom_minimum_size = Vector2(px, px)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r
