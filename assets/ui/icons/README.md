# Echoes Beyond Earth — UI Icons

Original, hand-authored SVG set (24×24 grid, 2 px stroke, square caps, white so they can be
tinted with `modulate` / `self_modulate`). No third-party artwork is bundled; no attribution needed.

Shape language (Direction A): geometry, not decoration. **Scanner states are distinguished by
shape, never by colour alone** — `signal_none` (dashed ring) → `signal_faint` (ring) →
`signal_moderate` (diamond) → `signal_strong` (triangle) → `signal_dig` (solid disc).

Usage:
```gdscript
$TextureRect.texture = UITokens.icon("journal")      # see scripts/ui/ui_tokens.gd
$TextureRect.modulate = UITokens.SIGNAL_GOLD
```
Plex does not contain ◆ ◇ ● ▲ ✕ ▶ ⏸ ⚙ — use these icons instead of those glyphs.
