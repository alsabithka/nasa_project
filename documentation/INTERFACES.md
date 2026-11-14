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
