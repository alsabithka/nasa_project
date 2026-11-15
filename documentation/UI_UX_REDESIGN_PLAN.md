# Echoes Beyond Earth — UI/UX Redesign Plan
**Direction A — Declassified Archive**
_Version 1.0 · Phase 0 baseline · Engine: Godot 4.x · Language: GDScript_


> **Merge note (Phase 9).** This plan is harsh's original. In the merged project the design direction is unchanged, but
> §4.5 Gallery and Phase 7 "Gallery & Artifacts" cover only the **Journal**: the spacecraft gallery / inspector, the video
> player and the excavation menu were not ported. A bottom-right **radar** (`RadarDial`) was added to the scanner. See
> `documentation/MERGE_LOG.md` and `INTERFACES.md` §6.

---

## 1. Design Direction Overview

### Direction A — Declassified Archive

The UI speaks like a real instrument panel recovered from a 1970s deep-space programme and cross-referenced with modern mission-control software. No skeuomorphic chrome, no sci-fi glow-spam — only structure, data density, and deliberate restraint.

| Pillar | Description |
|---|---|
| **Swiss grid** | 8-column layout grid, 4-pt baseline, hard-ruled gutters. Every element locks to the grid or justifies its deviation. |
| **Monochrome base** | The palette is built on Ink (dark surfaces) and Paper (light text). Colour is reserved for signal — status, warnings, discoveries. |
| **Brutalist hard edges** | Panels use 0 px corner radius. No drop-shadows. Borders communicate structure; they are not decoration. |
| **Retro mono numerals** | Live telemetry, coordinates, and counters always render in IBM Plex Mono. This separates facts from prose. |

---

## 2. Design Principles

### 2.1 One Voice — Three Registers

The game speaks in a single authorial voice that shifts register depending on context.

| Register | Context | Characteristics |
|---|---|---|
| **Instrument** | HUD, Scanner, Telemetry panels | Mono font, uppercase labels, signal-colour accents, dense data layout |
| **Archive** | Journal, Gallery, Menu | Proportional font, sentence-case, generous whitespace, paper tones |
| **Cinema** | Cutscenes, Onboarding, Discovery moments | Full-bleed imagery, minimal text, slow-motion transitions, LAYER_CINEMA |

### 2.2 Structure is Information

Spatial relationships encode meaning. A panel border says "this data belongs together". A gutter says "these systems are separate". Avoid decorative separators — if a line exists, it carries semantic weight.

### 2.3 Facts and Fiction Look Different

Telemetry data always uses `UITokens.SIGNAL_*` colours and IBM Plex Mono. Narrative text always uses `UITokens.PAPER_*` tones and IBM Plex Sans. A player can tell at a glance whether they are reading a measurement or a story.

---

## 3. Token Reference

### 3.1 Colour Palette

| Token | Hex | Role |
|---|---|---|
| `INK_900` | `#07090D` | Deepest background, void of space |
| `INK_800` | `#0D1117` | Default panel background |
| `INK_700` | `#151B24` | Elevated surface (cards, drawers) |
| `INK_600` | `#2A3442` | Borders, dividers, inactive controls |
| `PAPER_100` | `#E8EAED` | Primary body text |
| `PAPER_300` | `#A3ACB9` | Secondary / caption text |
| `PAPER_500` | `#7C8797` | Disabled / placeholder text |
| `SIGNAL_GOLD` | `#FAC733` | Discoveries, highlights, warnings |
| `SIGNAL_CYAN` | `#80CCFF` | Telemetry, links, focus rings |
| `SIGNAL_RED` | `#FF5A4D` | Errors, critical alerts |
| `SIGNAL_GREEN` | `#5FE08A` | Success, confirmed readings |

### 3.2 Typography Scale

| Token | Size (px) | Usage |
|---|---|---|
| `TEXT_CAPTION` | 12 | Timestamps, footnotes, axis labels |
| `TEXT_BODY` | 14 | Default UI text, journal prose |
| `TEXT_LEAD` | 16 | Panel subtitles, list items |
| `TEXT_TITLE` | 20 | Panel headers, section titles |
| `TEXT_DISPLAY` | 28 | Screen titles, modal headers |
| `TEXT_HERO` | 40 | Main menu logotype, cinematic text |

**Font candidates (open-licence, Google Fonts):**

| Role | Typeface | Note |
|---|---|---|
| UI body / headers | **IBM Plex Sans** _(preferred)_ or **Archivo** | Verify licence before bundling. Both available on Google Fonts under OFL. |
| Numerals / data readouts | **IBM Plex Mono** | Tabular figures, monospaced, visually separates data from prose |

> [!IMPORTANT]
> Download fonts from Google Fonts and store them in `assets/fonts/` before shipping. Confirm the OFL licence covers in-game distribution with your team lead.

### 3.3 Spacing Scale (4-pt grid)

| Token | Value (px) | Common use |
|---|---|---|
| `SP_1` | 4 | Icon-to-label gap, inline padding |
| `SP_2` | 8 | Control internal padding |
| `SP_3` | 12 | Small component gap |
| `SP_4` | 16 | Standard margin, panel padding |
| `SP_6` | 24 | Section spacing |
| `SP_8` | 32 | Panel-to-panel gap |
| `SP_12` | 48 | Full-screen section break |

### 3.4 Shape Tokens

| Token | Value (px) | Usage |
|---|---|---|
| `RADIUS_PANEL` | 0 | All panel containers — sharp corners |
| `RADIUS_CONTROL` | 2 | Buttons, inputs — barely rounded |
| `BORDER_PANEL` | 1 | Panel outlines |
| `BORDER_CONTROL` | 2 | Interactive control outlines |
| `BORDER_FOCUS` | 2 | Keyboard / gamepad focus ring |

### 3.5 Motion Tokens

| Token | Duration (s) | Usage |
|---|---|---|
| `DURATION_INSTANT` | 0.00 | State changes with no perceived animation |
| `DURATION_FAST` | 0.12 | Hover, press feedback, tooltips |
| `DURATION_BASE` | 0.20 | Panel open/close, tab switch |
| `DURATION_SLOW` | 0.40 | Drawer slide, page transition |
| `DURATION_CINEMATIC` | 0.80 | Cutscene overlays, discovery reveals |

### 3.6 Canvas Layer Scheme

| Token | Layer Index | Description |
|---|---|---|
| `LAYER_WORLD_HUD` | 0 | Elements anchored to the 3-D world (floating labels) |
| `LAYER_TELEMETRY` | 5 | Persistent HUD overlays (vitals, coordinates) |
| `LAYER_OVERLAYS` | 10 | Contextual panels, tooltips, scanner readout |
| `LAYER_MODALS` | 20 | Confirmation dialogs, inventory, journal |
| `LAYER_CINEMA` | 30 | Cutscene black bars, discovery sequences |
| `LAYER_SYSTEM` | 40 | Pause menu, settings |
| `LAYER_DEBUG` | 50 | Debug overlays — stripped in release builds |

---

## 4. Screen-by-Screen Design Targets

### 4.1 Main Menu
- **Register:** Archive
- Full INK_900 background. Logotype at TEXT_HERO in PAPER_100.
- Three primary actions (New Mission, Continue, Settings) aligned to left column of the grid, vertically centred.
- Subtle animated star-field behind — no UI animation, motion reserved for the world layer.
- Build version printed in TEXT_CAPTION / PAPER_500 at bottom-right.

### 4.2 HUD (In-Flight / On-Surface)
- **Register:** Instrument
- Persistent CanvasLayer at LAYER_TELEMETRY (5).
- Four corners: top-left = mission objective; top-right = coordinates + altitude in IBM Plex Mono / SIGNAL_CYAN; bottom-left = suit/fuel status bars using SIGNAL_GREEN → SIGNAL_GOLD → SIGNAL_RED; bottom-right = mini-map or compass.
- All labels uppercase, TEXT_CAPTION or TEXT_BODY.
- Borders: BORDER_PANEL (1 px), INK_600.

### 4.3 Scanner Panel
- **Register:** Instrument
- Slides in from the right at LAYER_OVERLAYS (10), DURATION_SLOW transition.
- Signal-strength readout in IBM Plex Mono / SIGNAL_GOLD.
- Spectrogram bar chart (custom drawn via `_draw()`) using SIGNAL_CYAN bars on INK_800 background.
- "ANOMALY DETECTED" alert in SIGNAL_RED, uppercase, TEXT_TITLE.

### 4.4 Journal
- **Register:** Archive
- Full-panel modal at LAYER_MODALS (20).
- Left sidebar: entry list in TEXT_BODY / PAPER_300, selected entry highlighted with SIGNAL_GOLD left border.
- Right content: entry text in TEXT_BODY / PAPER_100, section headers in TEXT_TITLE.
- Timestamps in IBM Plex Mono / PAPER_500.

### 4.5 Gallery (Artifact / Image Viewer)
- **Register:** Archive → Cinema (on zoom)
- Grid of collected artifacts; thumbnail cards on INK_700 with 1-px INK_600 border.
- On selection: fade to LAYER_CINEMA, show artifact full-screen with TEXT_LEAD caption in PAPER_100 below.
- Transition: DURATION_CINEMATIC fade-in.

### 4.6 Pause Menu
- **Register:** Instrument / Archive hybrid
- Overlay at LAYER_SYSTEM (40). INK_900 at 85% opacity over the frozen frame.
- Four options in TEXT_TITLE / PAPER_100, left-aligned with SP_6 vertical gap.
- "PAUSED" label in TEXT_DISPLAY / SIGNAL_GOLD, top-left.

### 4.7 Settings
- **Register:** Archive
- Full-panel at LAYER_SYSTEM (40). Two-column layout: category list left, options right.
- Sliders use SIGNAL_CYAN fill. Toggle switches use SIGNAL_GREEN (on) / INK_600 (off).
- Section headers in TEXT_TITLE / PAPER_300, uppercase.

### 4.8 Onboarding / Tutorial
- **Register:** Cinema → Instrument
- Begins at LAYER_CINEMA (30) with full-bleed imagery and TEXT_LEAD narration.
- Transitions to LAYER_OVERLAYS for in-world tooltip callouts.
- Callout boxes: INK_800 panel with BORDER_FOCUS SIGNAL_CYAN outline, arrow pointing at target element.
- Dismiss via gamepad confirm or mouse click; DURATION_FAST fade-out.

---

## 5. Using `ui_tokens.gd` in Code

`UITokens` is a plain static class — no Autoload required. Import it by referencing the class name directly after Godot has indexed the script.

```gdscript
# Example: style a panel programmatically
func _ready() -> void:
    var style := StyleBoxFlat.new()
    style.bg_color         = UITokens.INK_800
    style.border_color     = UITokens.INK_600
    style.border_width_top    = UITokens.BORDER_PANEL
    style.border_width_bottom = UITokens.BORDER_PANEL
    style.border_width_left   = UITokens.BORDER_PANEL
    style.border_width_right  = UITokens.BORDER_PANEL
    style.corner_radius_top_left     = UITokens.RADIUS_PANEL
    style.corner_radius_top_right    = UITokens.RADIUS_PANEL
    style.corner_radius_bottom_left  = UITokens.RADIUS_PANEL
    style.corner_radius_bottom_right = UITokens.RADIUS_PANEL
    $Panel.add_theme_stylebox_override("panel", style)

# Example: drive a Tween with motion tokens
func open_panel() -> void:
    var tween := create_tween()
    tween.tween_property($ScannerPanel, "position:x", 0.0, UITokens.DURATION_SLOW)

# Example: set a label font size
func style_header(label: Label) -> void:
    label.add_theme_font_size_override("font_size", UITokens.TEXT_TITLE)
    label.add_theme_color_override("font_color", UITokens.PAPER_100)
```

> [!TIP]
> Because all tokens are `static var`, they are readable as class-level constants (`UITokens.SP_4`) without instantiating the class. Never add UITokens to Autoloads — this avoids circular dependencies and keeps load order predictable.

---

## 6. Phase Roadmap

| Phase | Title | Deliverable |
|---|---|---|
| **0** | Token Foundation | `ui_tokens.gd` + this design plan |
| **1** | Theme & Base Styles | Godot Theme resource wired to UITokens; base StyleBoxes for Panel, Button, Label |
| **2** | HUD Rebuild | Telemetry panel, objective tracker, mini-map shell |
| **3** | Scanner Panel | Slide-in scanner with spectrogram and anomaly alert |
| **4** | Journal | Full journal modal — entry list, content view, timestamps |
| **5** | Main Menu | Menu scene rebuild — logotype, action column, star-field |
| **6** | Pause & Settings | Pause overlay, settings two-column layout, sliders/toggles |
| **7** | Gallery & Artifacts | Artifact grid, full-screen viewer, Cinema-layer transition |
| **8** | Onboarding / Tutorial | Cinema intro sequence, in-world callout system |
| **9** | Polish & Accessibility | Motion-reduce mode, font-size scale, colour-blind signal swap, final QA |

---

## 7. File Ownership

| File | Phase | Owner workstream |
|---|---|---|
| `scripts/ui/ui_tokens.gd` | 0 | UI Foundation |
| `documentation/UI_UX_REDESIGN_PLAN.md` | 0 | UI Foundation |
| `theme/echoes_theme.tres` | 1 | UI Foundation |
| `scenes/ui/hud.tscn` | 2 | HUD workstream |
| `scripts/ui/hud_controller.gd` | 2 | HUD workstream |
| `scenes/ui/scanner_panel.tscn` | 3 | Scanner workstream |
| `scenes/ui/journal.tscn` | 4 | Journal workstream |
| `scenes/ui/main_menu.tscn` | 5 | Menu workstream |

> [!NOTE]
> Phase 0 creates **no** `.tscn` files and modifies **no** existing `.gd` files or `project.godot`. All subsequent phases must follow `AGENTS.md` ownership rules — do not edit a file you do not own without coordination.

---

_End of UI/UX Redesign Plan — Phase 0 baseline._
