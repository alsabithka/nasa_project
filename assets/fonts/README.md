# Echoes Beyond Earth — Fonts

Bundled (SIL OFL 1.1 — see `OFL.txt`, credits in `/CREDITS.md`):

| Role | File |
|---|---|
| UI body | `IBMPlexSans-Regular.ttf` |
| Buttons, leads | `IBMPlexSans-Medium.ttf` |
| Titles, display | `IBMPlexSans-Bold.ttf` |
| Live numerals (mono) | `IBMPlexMono-Regular.ttf`, `IBMPlexMono-Medium.ttf` |

They are referenced by `ui/theme/ebe_theme.tres` (default font + type variations). Do not set fonts in scenes —
use `theme_type_variation` (`TitleLabel`, `StatLabel`, …).

Glyph coverage verified: ° ₂ · × – … → ✓. Plex has **no** ◆ ◇ ● ▲ ✕ ▶ ⏸ ⚙ ○ — use `assets/ui/icons/*.svg`.
