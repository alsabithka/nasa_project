# Echoes Beyond Earth — Design System MASTER
**Direction A · "Declassified Archive"** · engine: Godot 4 · language: GDScript
Source of truth for tokens: `design-tokens.json` → mirrored in `scripts/ui/ui_tokens.gd` and `ui/theme/ebe_theme.tres`.
Per-screen exceptions live in `pages/<screen>.md` and override this file.

## 1. Idea
A NASA technical-report / archive-folder language turned into a game UI. Structure is information: rules, labels and
numbering exist only when they mean something. Documented facts and in-game simulation **look different**.

| Style borrowed | Its one job |
|---|---|
| Monochrome | Ink/paper base for every screen; the high-contrast accessibility mode |
| Swiss | Grid, left alignment, hierarchy by size and weight instead of boxes |
| Brutalism | Hard 1–2 px rules, square corners, hard 4,4 offset shadow on archive cards / discovery stamp only |
| Retro terminal | Monospace numerals for live readouts (distance, gravity, heading, MET) — nothing else |
| Bauhaus | Geometric symbols (circle · diamond · triangle · disc) and the gold/cyan/red status triad |
| Cyberpunk | **Not used** as a theme. Only a faint scan-line feel may be borrowed for the scanner widget |

Cross-check (ui-ux-pro-max database, `--design-system`): closest listed style "HUD / Sci-Fi FUI" is rated **accessibility
risk: high** (requires contrast 4.5:1, keyboard, visible focus, reduced motion) — which is why glow, neon and glitch are
excluded and those four requirements are hard rules here.

## 2. Registers (three behaviours, one voice)
- **Instrument** — in the world: HUD, scanner, prompts. Translucent, minimal, never blocks the view (`HudPanel`).
- **Archive** — catalogue, journal, gallery, menus. Document-like, structured, calm (`ArchiveCard`).
- **Cinema** — story player. Full-screen, restrained. Already built; re-skin only.

## 3. Tokens
See `design-tokens.json`. Highlights:
- One accent per component. Gold text on gold fill is **forbidden** → `ink-900` on gold (12.6:1).
- Control borders use `paper-500` (≥3:1). `ink-600` is decorative only.
- Status is never colour alone: always icon/shape + text (scanner states are ○ ◇ △ ● icons, not tints).
- Six type sizes (12/14/16/20/28/40). Body ≥ 14. Numerals that update live use IBM Plex Mono.
- Spacing 4-pt scale. Radii: panels 0, controls 2. Focus ring: 2 px **gold**, 2 px outside the control.

## 4. Components (scenes/scripts under `scenes/ui/components`, `scripts/ui/components`)
| Component | Class / variation | Purpose |
|---|---|---|
| ArchiveCard | `ArchiveCard` (panel variation) | Archive-register panel (1 px ink-600, optional hard shadow) |
| HudPanel | `HudPanel` | Translucent instrument panel |
| KeyCap | `KeyCap` | Key hint read from the InputMap (`action_name`) |
| StatReadout | `StatReadout` | Caption + mono value + unit (+ `SIM` badge when simulated) |
| SegmentedMeter | `SegmentedMeter` | Segment-count meter, one accent colour |
| ArchiveTabs | `ArchiveTabs` / `TabButton` | Toggle tabs; selected = gold text + 3 px underline |
| ListRow | `ListRow` | Selectable row: icon · title · subtitle · trailing |
| Badge | `Badge` | ARCHIVE / SIM / LIVE / CATALOGUED / LOCKED (icon + text) |
| Toast | `Toast` | Self-dismissing event banner |
| ConfirmDialog | `ConfirmDialog` | Modal yes/no; Cancel focused first, Esc cancels |
| SectionHeader | `SectionHeader` | Caption + rule |
| SpecimenReveal | `SpecimenReveal` | Vector specimen under dust cells (cleaning mini-game) |

Buttons: `Button` (default), `PrimaryButton` (gold fill, ink text), `GhostButton` (paper-500 border), `TabButton`.
Labels: `CaptionLabel`, `LeadLabel`, `TitleLabel`, `DisplayLabel`, `HeroLabel`, `StatLabel`, `StatLabelLarge`, `GoldLabel`.

## 5. Rules (checked in Phase 9)
1. No hard-coded colours or font sizes in scenes/scripts — use `UITokens` or the Theme.
2. No glyph icons (◆ ● ▲ ✕ ▶ ⚙ are not in Plex) — use `assets/ui/icons/*.svg` via `UITokens.icon()`.
3. No colour via `modulate` for state; use theme styles/variations.
4. Every interactive control: visible focus, focus order, ≥ 3:1 border.
5. Key hints come from the InputMap, never typed as literals.
6. Motion durations come from tokens and become 0 with reduced motion. Nothing loops decoratively.
7. Layers come from `UITokens.LAYER_*`.
8. Fact vs simulation: archive data in `ARCHIVE RECORD` blocks; gameplay values in `FIELD READINGS (SIM)` blocks.

## 6. Anti-patterns (this project)
Rounded "app" cards · multiple panel languages · icon-topped identical cards · glow/neon · glass blur ·
placeholder grey boxes · text walls with equal weight · raw `[b]` markup shown to players · float years (`1971.0`).

## 7. Assets
Fonts: IBM Plex Sans / Mono (SIL OFL 1.1) in `assets/fonts/` — see `CREDITS.md`. Icons: original SVG set in `assets/ui/icons/`.
