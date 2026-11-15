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
