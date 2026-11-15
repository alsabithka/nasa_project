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

Stable Artifact IDs:
- Moon: `apollo_lrv`, `apollo_lm_descent_stage`, `alsep`
- Mars: `sojourner`, `opportunity`, `ingenuity`

---

## 6. Artifact Documentary Player (`scripts/ui/artifact_video_player.gd`)
Scene: `scenes/ui/artifact_video_player.tscn` (`CanvasLayer`, layer 20). Spawned by the HUD when the player chooses WATCH STORY in the Catalogue Entry (`HUD.play_artifact_story(id)`).
It plays the artifact's documentary video when one is `ready` in the manifest and otherwise runs the original
text flashback (`scenes/ui/flashback.tscn`). Full guide: `documentation/ARTIFACT_VIDEO_WORKFLOW.md`.

```gdscript
@export var artifact_id: String = ""        # existing id from artifacts.json
@export var allow_placeholder: bool = false # preview/tests only

# Emitted exactly once. result = "completed" | "skipped" | "fallback"
signal playback_complete(artifact_id: String, result: String)
```

The previous `flashback_complete()` signal on `flashback_system.gd` is unchanged.

### Manifest helper (`scripts/ui/artifact_video_manifest.gd`)
Static helper (not an Autoload). Use via `const Manifest = preload("res://scripts/ui/artifact_video_manifest.gd")`.

```gdscript
static func is_playable(artifact_id: String, allow_placeholder: bool = false) -> bool
static func get_entry(artifact_id: String) -> Dictionary
static func get_settings() -> Dictionary
static func get_series() -> Dictionary
static func validate_entry(artifact_id: String) -> Array   # empty = valid
static func parse_srt(path: String) -> Array
```

### Artifact video manifest (`data/artifact_videos.json`)
Keys under `videos` are the existing stable artifact IDs. Fields are documented in
`documentation/ARTIFACT_VIDEO_WORKFLOW.md` §4. Video format: Ogg Theora (`.ogv`) under
`assets/videos/<artifact_id>/`. Subtitles, chapters, lower thirds, footage credits, sources and attribution
are data, not burned into the video. Design standard: `documentation/ARTIFACT_VIDEO_TEMPLATE.md`.


## Phase 3 additions (UI shell)
| Name | Kind | Contract |
|---|---|---|
| `SettingsStore` | static class (`scripts/ui/settings_store.gd`) | `get_value(key)`, `set_value(key, v)`, `save()`, `reload()`, `apply(tree)`, `motion_scale()`, `mouse_sensitivity_value()`, `has_bus(name)`, `first_run_pending()`, `mark_first_run_done()`. File: `user://settings.cfg`, section `settings`. |
| `ModalShell` | `CanvasLayer` | Set `title_text`/`card_width` (or subclass and override `_build_content()`), add `body` children, call `open(focus_control)`; `close()`; signal `closed`. Esc closes and is consumed. |
| `ChapterButton` | `Button` | `setup(title, icon_name, found, total, lock_reason := "")`; a non-empty `lock_reason` disables the button and shows the reason. |
| `HeroBackdrop` | `Control` | Drawn backdrop; no inputs. |
| Pause menu | `scenes/ui/pause_menu.tscn` | `show_pause()`, `hide_pause()`, `is_open()`; signals `resume_requested`, `open_journal_requested` (`open_settings_requested` deprecated, no longer emitted). |
| Settings menu | `scenes/ui/settings_menu.tscn` | `show_settings()`; signal `settings_closed`. |
| Field manual | `scenes/ui/field_manual.tscn` | `show_manual()`; signal `manual_closed`; static `should_show()`. |
| `SceneFade` | `SceneFade.go(tree, path)` | Fade out, change scene, fade in, self-free. |


## Phase 4 additions (world HUD)
| Name | Kind | Contract |
|---|---|---|
| `WorldHud` | `Control` (class_name) | Created by `hud.gd`. `set_progress(planet, found, total)`, `show_prompt(action, verb)`, `hide_prompt()`; signals `journal_pressed`, `pause_pressed`; fields `scanner`, `journal_button`, `menu_button`. |
| `ScannerInstrument` | `HudPanel` | `update_reading(target_id, distance, strength)`, `reset()`, `get_state()`; enum `State {NONE, FAINT, MODERATE, STRONG, DIG}`; signal `state_changed(int)`. Never exposes artifact identity. |
| `AstronautHelmetHUD` | `CanvasLayer` | Unchanged name and public labels: `suit_pressure_label`, `consumables_label`, `heart_rate_label`, `gait_label`, `gravity_label`, `compass_label`, `view_mode_label`, `mission_clock_label`. |


## Phase 5 additions (discovery pipeline)
Flow: `excavation_menu` -> dig -> `dig_clean_ui` -> **Catalogue Entry** -> (optional) story player. The HUD discovery popup no longer exists.

| Name | Kind | Contract |
|---|---|---|
| Catalogue Entry | `scripts/ui/scientific_examination_panel.gd` on a `CanvasLayer` (layer 20) | Set `artifact_id` before `add_child`. Signals `documentation_closed(artifact_id)` (always, once) and `story_requested(artifact_id)` (only for WATCH STORY, emitted just before `documentation_closed`). Fields `title_label`, `category_badge`, `index_label`, `measured_label`, `estimated_label`, `close_button`, `story_button`, `stamp`. Keyboard is ignored for `ARM_DELAY` (0.8 s) after opening. Path kept for compatibility; the file is the former "Scientific Examination panel". |
| `CatalogueStamp` | `Control` (class_name) | `slam()`; signal `stamped`; reduced motion shows it instantly. |
| Excavation prompt | `scripts/ui/excavation_menu.gd` on a `CanvasLayer` (layer 40) | Unchanged contract: signals `begin_excavation_requested`, `inspect_signal_requested`, `menu_cancelled`; `set_anomaly_details(title, depth, sig)`; fields `_title_label`, `_details_label`. Esc is consumed in `_input`. |
| `HUD` | `Control` | Joins group `"hud"`. New `play_artifact_story(artifact_id)`. `_on_popup_closed()` kept as a compatibility shim (starts the story for the last discovered artifact). |
| `WorldHud` | group `"world_hud"` | `artifact.gd` calls `show_prompt("interact", verb)` / `hide_prompt()` through `get_tree().call_group("world_hud", ...)`. |
| `artifact.gd` | `Area3D` | The `Label3D` prompt is no longer shown (node kept). `_on_documentation_closed` hands WATCH STORY to the HUD; with CONTINUE (or no HUD) it recaptures the mouse as before. |


## Phase 6 additions (journal, gallery, inspector)
| Name | Kind | Contract |
|---|---|---|
| `JournalDrawer` | `CanvasLayer` (class_name, layer `LAYER_MODALS`) | Created by `hud.gd` (`HUD.journal`). `open(planet := "")`, `close()`, `refresh()`, `show_planet(planet)`, `select_artifact(id)`, `is_open()`, static `has_story(id)`; signals `closed`, `story_requested(artifact_id)`; fields `planet`, `category_filter`, `selected_id`, `slots`, `filter_buttons`, `tabs`, `detail_name`, `read_more_button`, `story_button`. Esc is consumed in `_input`. Const `SPOILER_FREE`. |
| `JournalSlot` | `PanelContainer` (class_name) | `JournalSlot.make(id, number, data, recovered, locked_caption)`; static `shape_for(category)`; signals `activated(id)`, `focused(id)`; `selected`. Locked slots never show name or category. |
| `HUD` | `Control` | `journal` replaces the `JournalModal` nodes (removed from `hud.tscn`). `toggle_journal()` and `_populate_journal(planet)` keep working. `selected_journal_planet` starts as `current_planet`. |
| Spacecraft gallery | `scenes/spacecraft/spacecraft_gallery.tscn` | Unchanged: `spacecraft_list` (5), `mount_point`, `current_craft_index`, `select_next_spacecraft()`, `select_prev_spacecraft()`, `toggle_component_inspector()`. New: `toggle_auto_rotate()`, fields `title_label`, `subtitle_label`, `stats_label`, `position_label`, `rail_panel`, `info_panel`. |
| `SpacecraftInspectorHUD` | `CanvasLayer` | Unchanged: `open_inspector(node, id)`, `close_inspector()`, `_on_prev_pressed()`, `_on_next_pressed()`, `_components`, labels `title_label`, `subtitle_label`, `comp_name_label`, `comp_desc_label`, `comp_spec_label` (text starts with `SPECIFICATIONS:`), `counter_label` (`COMPONENT 01 / 04`); signal `inspection_closed`. New: `progress_meter`, `prev_button`, `next_button`, `close_button`, `panel`. |
| Input actions | `scripts/input/input_setup.gd` | New `gallery_inspect` (I), `gallery_rotate` (Space); gamepad: `gallery_prev` LB, `gallery_next` RB, `gallery_inspect` Y, `gallery_rotate` X. |
