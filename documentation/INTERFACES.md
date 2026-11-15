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
Scene: `scenes/ui/artifact_video_player.tscn` (`CanvasLayer`, layer 20). Spawned by the HUD after the discovery popup closes.
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
