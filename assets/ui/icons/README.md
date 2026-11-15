# Echoes Beyond Earth — UI Icons

Place SVG icon files here: `assets/ui/icons/*.svg`

## Required Icons (Phase 2+)

| Filename | Usage | Unicode fallback today |
|----------|-------|----------------------|
| `scan.svg` | Scanner widget state | ○ ◇ ▲ ● |
| `dig.svg` | Excavation prompt | ⬇ |
| `brush.svg` | Cleaning screen | ~ |
| `journal.svg` | Journal button | ◉ |
| `pause.svg` | Pause menu | ⏸ |
| `settings.svg` | Settings screen | ⚙ |
| `play.svg` | Story player | ▶ |
| `check.svg` | Collected artifact | ✓ |
| `lock.svg` | Locked artifact/planet | ● |
| `moon.svg` | Moon chapter marker | ○ |
| `mars.svg` | Mars chapter marker | ◆ |
| `close.svg` | Close / dismiss | ✕ |

## Recommended Sources (open-licence)

- **Phosphor Icons** — https://phosphoricons.com (MIT)
- **Heroicons** — https://heroicons.com (MIT)
- **Lucide** — https://lucide.dev (ISC)

## Import Settings

In Godot, import each SVG as:
- Type: **Texture2D**
- Compress mode: **Lossless**
- Scale: 1.0 (icons are sized via `expand_mode` in TextureRect)

## Usage in GDScript

```gdscript
var icon := preload("res://assets/ui/icons/journal.svg")
$TextureRect.texture = icon
```

Do NOT bundle icons that are not open-licence without legal approval.
