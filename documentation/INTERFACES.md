# Echoes Beyond Earth — Shared Interfaces & API Contract

This document defines the strict contracts and public interfaces between all systems in the project.

---

## 1. Player Interface (`scripts/player/player.gd`)
Attached to `Player` (`CharacterBody3D`).

```gdscript
# Required by Scanner and Level systems
func get_scan_origin() -> Vector3:
    return global_position

# Movement configuration
@export var speed: float = 7.0
@export var jump_velocity: float = 8.5
@export var gravity: float = 4.0 # Default Moon gravity (customizable per level)
```

---

## 2. Artifact Interface (`scripts/artifact/artifact.gd`)
Attached to `Artifact` (`Area3D`).

```gdscript
@export var artifact_id: String = "" # Stable ID e.g. "apollo_lrv"

func get_artifact_id() -> String:
    return artifact_id

func get_world_position() -> Vector3:
    return global_position

func interact() -> void:
    GameState.register_artifact(artifact_id)
```

---

## 3. Scanner Interface (`scripts/scanner/scanner.gd`)
Attached to `Scanner` (`Node3D` / component on Player).

```gdscript
signal scan_updated(target_id: String, distance: float, signal_strength: float)

func get_current_target() -> String
func get_signal_strength() -> float # 0.0 to 1.0
func get_target_distance() -> float
```

---

## 4. GameState Autoload (`scripts/autoload/game_state.gd`)
Global Autoload singleton: `GameState`.

```gdscript
signal artifact_recovered(artifact_id: String)
signal mission_completed(planet: String)
signal planet_unlocked(planet: String)

func register_artifact(artifact_id: String) -> void
func is_artifact_recovered(artifact_id: String) -> bool
func get_artifact_data(artifact_id: String) -> Dictionary
func get_recovered_count(planet: String) -> int
func get_total_count(planet: String) -> int
func is_planet_unlocked(planet: String) -> bool
func unlock_planet(planet: String) -> void
```

---

## 5. Artifact Data Format (`data/artifacts.json`)

```json
{
  "id": "ingenuity",
  "name": "Ingenuity Mars Helicopter",
  "location": "Mars",
  "mission": "Mars 2020",
  "year": 2021,
  "purpose": "Technology demonstration of powered flight",
  "status": "Grounded after rotor damage",
  "history": "Verified historical narrative goes here",
  "sources": ["NASA official mission page"]
}
```

Each record also carries the optional richer fields used by the Catalogue Entry and Journal (merge D3):
`category, detection_signature, dimensions_cm, discovery_depth_cm, estimated_properties, geological_context,
mass_kg, measured_properties, stratigraphic_layer`. UI code must treat every one of them as optional.

Stable Artifact IDs (16 total, merge D2 — the 9 harsh-only entries were not added):
- Moon (3): `apollo_lrv`, `apollo_lm_descent_stage`, `alsep`
- Mars (13): `sojourner`, `opportunity`, `ingenuity`, and 10 more — see `data/artifacts.json`

GameState also keeps integrated1's resources: `energy`, `max_energy`, `minerals`, signal `resources_updated`;
`register_artifact()` adds 280 minerals.

---

## 6. UI contracts (merge: integrated1 gameplay + harsh "Declassified Archive")
All UI is built from `scripts/ui/components/*` and `ui/theme/ebe_theme.tres`; tokens come from `UITokens`
(static class, not an autoload) and user settings from `SettingsStore` (static, `user://`). Rules: `design-system/echoes-beyond-earth/MASTER.md`.

### 6.1 HUD (`scripts/ui/hud.gd`, `scenes/ui/hud.tscn`)
```gdscript
var world_hud: WorldHud          # top-left progress + resources, top-right Journal/Pause, bottom-right scanner, centre prompt
var journal: JournalDrawer
var radar_panel: Control         # == world_hud.scanner; hidden while a modal is open
@export var current_planet: String
func toggle_journal() -> void
func play_artifact_story(artifact_id: String) -> void   # WATCH STORY -> res://scenes/ui/flashback.tscn (merge D5)
func is_modal_blocking() -> bool                        # true while any node of group "blocking_modal" is visible
```
Node group `hud` is joined by the HUD; `blocking_modal` by dig, clean, Catalogue Entry, flashback, every `ModalShell`.
Esc policy: the topmost blocking modal consumes Esc in `_input`; the HUD opens pause only when none is open.

### 6.2 ScannerInstrument + RadarDial (bottom-right)
```gdscript
# scripts/ui/components/scanner_instrument.gd
signal state_changed(new_state: int)
const MAX_RANGE := 65.0; const DIG_RANGE := 4.0; const STRONG_RANGE := 15.0; const MODERATE_RANGE := 35.0   # merge D8
func update_reading(target_id: String, distance: float, strength: float) -> void   # fed by Scanner.scan_updated via HUD
func get_state() -> int
func reset() -> void
# scripts/ui/components/radar_dial.gd  (new in the merge; harsh had no radar)
@export var radar_range: float = 65.0
func refresh_artifacts() -> void      # re-read the "artifact" group
func get_blip_count() -> int
func get_blips() -> Array
func get_player_position() -> Vector3
func set_enabled(v: bool) -> void
```
The radar shows position only, never identity (same rule as the scanner). Proximity is shown visually only: the scanner
audio ping stays disabled on purpose (`scanner.gd`).

### 6.3 Catalogue Entry (`scripts/ui/scientific_examination_panel.gd`, CanvasLayer)
```gdscript
signal documentation_closed(artifact_id: String)
signal story_requested(artifact_id: String)    # WATCH STORY; artifact.gd forwards it to hud.play_artifact_story()
```
Registration with `GameState` happens when the entry closes. It replaces the old discovery popup.

### 6.4 Dig and clean (`scripts/ui/dig_minigame.gd`, `scripts/ui/dig_clean_ui.gd`, layer `LAYER_MODALS`)
Rules and signals are integrated1's, unchanged: `dig_finished`, `dig_cancelled`, `cleaning_done(artifact_id)`.
Only the chrome and the specimen image (`SpecimenReveal`) are harsh's. `SpecimenReveal.backdrop: Texture2D` (default null) is
the drop-in point for a real photo (plan §2.4).

### 6.5 Flashback (`scenes/ui/flashback.tscn`)
`flashback_system.gd` is unchanged (`signal flashback_complete`, `@export artifact_id`, Space skips); `flashback_skin.gd`
(child `Skin`) adds badge, scene meter, key-caps and Esc-to-skip. Content: `data/flashbacks.json`.

### 6.6 Not ported from harsh (merge D4-D6)
Excavation menu, documentary video player + `artifact_videos.json`, spacecraft gallery + component inspector. The
`JournalDrawer.has_story()` check falls back to `data/flashbacks.json`.
