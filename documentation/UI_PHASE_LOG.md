# UI/UX redesign — phase log
Plan: `UI_UX_REDESIGN_PLAN.md` · Design system: `design-system/echoes-beyond-earth/MASTER.md`
Verification: Godot 4.4.1 headless + xvfb (`--rendering-driver opengl3`), screenshots via `scripts/qa/ui_screenshot.gd`.
`project.godot`, Autoloads, GameState signals and artifact IDs are **not** modified in any phase so far.

## Phases 0–2 (delivered together: the received zip already contained Phase 0/1 work and Phase 2 scaffolding)

### State found on arrival
- Phase 1: B2, B3, B7, B8, B9 and Esc→pause→confirm were already in place. **B4 (gallery bar) and B5 (grey cleaning box) were not fixed**
  (B4 only scrolled sideways; the dig scene was untouched despite "B5 FIX" comments in the script). B6 was a colour tint only.
- Phase 2: tokens, theme and 7 components existed but **no fonts and no icons were bundled** (README stubs only), the theme set no font,
  `KeyCap` could not compile (`PackedStringArray.map`) and showed nothing when created with `.new()`.

### Phase 0 — decide & prototype
Created: `design-system/echoes-beyond-earth/{MASTER.md, design-tokens.json, style-tile-A.html, style-tile-A.png, pages/*.md}`, `CREDITS.md`.
Direction A "Declassified Archive" adopted as the plan recommends (B/C tiles were not produced — no reason to, since A was chosen).

### Phase 1 — stabilise (remaining items)
- B4 `scripts/spacecraft/spacecraft_gallery.gd`: selector rail now wraps (HFlowContainer) + action row; no clipping at 1280/1366/1920.
- B5 `scenes/ui/dig_clean_ui.tscn`, `scripts/ui/dig_clean_ui.gd`, new `SpecimenReveal`: specimen emerges as dust cells fall away.
- B6 `scripts/ui/hud.gd`: journal tabs are toggle `TabButton`s (gold text + underline), no `modulate` tint.
- Contract kept: `cleaning_done(artifact_id)`, `artifact_id`, `clean_duration`.

### Phase 2 — foundation
- Fonts: IBM Plex Sans (Regular/Medium/Bold) + Mono (Regular/Medium), OFL text bundled.
- Icons: 23 original SVGs in `assets/ui/icons/` (scanner states differ by shape).
- Theme `ui/theme/ebe_theme.tres`: fonts wired; type variations (`Caption/Lead/Title/Display/Hero/Stat/StatLarge/GoldLabel`),
  `PrimaryButton`, `GhostButton`, `TabButton`, `ArchiveCard`, `HudPanel`; focus ring now **gold**.
- `scripts/ui/ui_tokens.gd`: `icon()`, `theme()`, `make_icon()` helpers.
- New components: `Badge`, `ArchiveTabs` (not `TabBar` — clashes with a Godot class), `ListRow`, `ConfirmDialog`, `SpecimenReveal`.
- Fixed: `KeyCap` (compiles; builds its own label; mono; paper-500 border), `SegmentedMeter` (one accent, no rainbow ramp),
  `StatReadout` (mono values, `simulated` → SIM badge).
- `scenes/ui/dev/component_gallery.tscn` shows every component and state.
- QA tool: `scripts/qa/ui_screenshot.gd`.

### Tests (Godot 4.4.1)
PASS: test_full_suite, test_lunar_terrain_and_gameplay, test_artifact_video_system, test_lunar_archaeology, test_historical_spacecraft_assets (91/91).
**FAIL (pre-existing, identical on the untouched zip):** test_interaction_stability — expects artifact state EXPOSED(3) but gets 4 after digging;
the test expectation is stale. Not changed.

### Known limitations
- Verified on Godot 4.4.1; the project declares 4.7 — open once in 4.7 to let it re-import.
- Main menu, HUD, exam/discovery panels, journal and inspector still use the old look until Phases 3–6.
- Plex does not contain ◆ ● ▲ ✕ glyphs still used in some strings; they are replaced by icons when each screen is migrated.


## Phase 3 — Shell: main menu, pause, settings, field manual

**Verification status: NOT run in Godot.** The sandbox had no Godot binary. Files were written against the Godot 4 API and
checked with a static lint only (tab indentation, bracket balance). Open the project once in 4.7, run the three test scripts
and the screenshot harness (see "How to test") before building on this.

### Found on arrival
- `main_menu.gd`, `pause_menu.gd`, `settings_menu.gd`, `field_manual.gd` existed as scaffolds in the OLD look (centred gold card,
  glyph characters, raw keys) with real defects:
  - Pause menu ran inside a paused tree without `PROCESS_MODE_ALWAYS`, so its buttons could not receive input.
  - `SceneFade` never faded back out: the opaque overlay stayed on top of the next scene.
  - Settings stored mouse sensitivity as 0.3 and wrote it straight to `player.mouse_sensitivity` (default 0.0028) = ~100x too fast.
  - Settings sliders for Music/SFX wrote to buses that do not exist; text scale was stored but never applied.
  - Pause hard-coded `KEY_R / KEY_J / KEY_M`; field manual hard-coded `KEY_*` and `[E]` in its text.
  - Pause also used the engine `ConfirmationDialog`; HUD and pause both opened settings.

### Created
- `scripts/ui/settings_store.gd` (`SettingsStore`, static, no Autoload): persistence in `user://settings.cfg`, `apply(tree)`, `motion_scale()`.
- `scripts/ui/components/modal_shell.gd` (`ModalShell`): shared system-modal frame (dim, ArchiveCard, Close + Esc key-cap, focus in/out, Esc consumed) and `style_slider()`.
- `scripts/ui/components/chapter_button.gd` (`ChapterButton`): planet chapter with progress meter, "n / total" mono count, locked state with reason.
- `scripts/ui/components/hero_backdrop.gd` (`HeroBackdrop`): drawn starfield, Earth disc, lunar horizon, survey grid. No textures, no motion.

### Rewritten
- `scenes/main_menu.tscn` + `scripts/main_menu.gd`: left-aligned column on the grid, chapters (Moon n/total, Mars locked with reason and not focusable),
  secondary actions (Spacecraft gallery, Field manual, Settings, Credits, Quit), initial focus on Moon. Old controls modal removed (superseded by the Field Manual).
- `scripts/ui/pause_menu.gd`: left panel, progress for the current planet, Resume / Journal / Settings / Field manual / Quit to menu,
  KeyCaps from the InputMap, `ConfirmDialog` for quit (danger style, Cancel focused), runs while paused, owns settings + manual.
- `scripts/ui/settings_menu.gd`: master volume, music/effects volume (rows only appear when those buses exist), mouse sensitivity (multiplier 0.25-2.0x),
  reduced motion (On/Off with icon), reset to defaults. Persists via `SettingsStore`.
- `scripts/ui/field_manual.gd`: 4 pages (Scan, Excavate, Catalogue, Controls), key-caps read from the InputMap, first-run flag in `SettingsStore`.
- `scripts/ui/scene_fade.gd`: fades out, changes scene, fades back in, frees itself; instant cut with reduced motion.

### Small edits to existing files
- `scripts/player/player.gd`: one line in `_ready` reads `SettingsStore.mouse_sensitivity_value()`.
- `scripts/ui/hud.gd`: removed the duplicate settings opener (the pause menu owns it now).

### Esc policy (whole game)
Top modal closes first (field manual / settings / confirm / discovery / journal); otherwise Esc opens pause; Esc in pause resumes.
Modals consume Esc, so no layer below sees it. Pause ignores Esc while its own child modal is open.

### Not done / limits
- Audio: the project has only the Master bus. Music/SFX sliders are hidden until buses named `Music` and `SFX` exist
  (needs a `default_bus_layout.tres` and routing of players: **approval item**, `project.godot` not touched).
- Text scale and high contrast are not shown yet (Phase 7); reduced motion currently affects scene fades and modal fades only (Phase 8 extends it).
- No hero imagery beyond the drawn backdrop (no Moon/Mars photography is bundled).
- `HUD` still shows "[ESC] Menu" in the old style until Phase 4.
- Component gallery was not extended with the three new components.


## Phase 4 — In-game HUD and scanner

**Verification status: NOT run in Godot** (no Godot binary in the authoring sandbox; static lint only). Run the tests and screenshots first.

### Zones (24 px safe margin, no overlaps by construction)
| Zone | Owner |
|---|---|
| top-left: planet, "n / total", progress meter | `WorldHud` |
| top-right: Journal + Pause buttons, each with a key-cap | `WorldHud` |
| bottom-right: scanner instrument | `ScannerInstrument` (in `WorldHud`) |
| bottom-left: suit telemetry | `scripts/ui/astronaut_helmet_hud.gd` (layer 5) |
| centre: reticle (first-person + mouse captured only), optional contextual prompt | `WorldHud` |

### Created
- `scripts/ui/components/world_hud.gd` (`WorldHud`): zones above; `set_progress()`, `show_prompt(action, verb)`, `hide_prompt()`; buttons use `FOCUS_NONE` so Space/Enter cannot fire them while the mouse is captured.
- `scripts/ui/components/scanner_instrument.gd` (`ScannerInstrument`): large mono distance, 10-segment meter, state = icon shape + words
  (searching / faint / moderate / strong / dig), LIVE badge. Same thresholds as before (4 / 12 / 25 / 60 m). Still shows no identity. Signal `state_changed`.

### Changed
- `scenes/ui/hud.tscn`: removed `TopBar` and `RadarWidget` (and their three unused styles). Modals (discovery, journal, completion) untouched (Phases 5-6).
- `scripts/ui/hud.gd`: builds `WorldHud`; scanner updates go to `ScannerInstrument`; node names `journal_button`, `menu_button`, `radar_panel` kept as variables.
  New toasts: "SIGNAL ACQUIRED" (once per target) and "<PLANET> UNLOCKED". Existing "ARTEFACT CATALOGUED" toast kept.
- `scripts/ui/astronaut_helmet_hud.gd`: no longer a top strip (this was bug B1). Bottom-left 3x2 grid, mono values, SIM badge on suit pressure, O2 and EVA clock;
  heart rate says "HIGH" in words as well as red; glyph/colour-only states removed; `[V]` text replaced by a key-cap from the InputMap.
  Public label fields and `AstronautHelmetHUD` node name kept for the existing tests. Gravity now shows "1.62 m/s2" without the g ratio (space).
- B10 (radar needle that never drew): resolved by removing the dead needle.

### Not done / limits
- The per-artifact `Label3D` prompt (`artifact.gd`) was NOT restyled: it is part of the discovery flow (Phase 5). `WorldHud.show_prompt()` exists and is unused until then.
- Telemetry stays a separate CanvasLayer (layer 5) because the tests and level scripts create it by name; the zone contract above is what prevents overlap.
- HUD area at rest is estimated at about 12% of the screen; measure it with the screenshot harness at 1280x720 and 1920x1080.
- Radar `Needle` and `RadarCircle` are gone, so any external script that referenced them would break (none found in the project).


## Phase 5 — Discovery pipeline

**Verification status: NOT run in Godot** (no Godot binary in the authoring sandbox; static lint only: tab indentation, bracket balance, typed-access review).
Run first: `test_full_suite`, `test_lunar_terrain_and_gameplay`, `test_artifact_video_system`, `test_lunar_archaeology`, and the new `test_phase5_discovery_ui`.

### Result: dig -> story is now TWO screens in one language
Before: cleaning -> *Scientific Examination* panel (different style) -> HUD *Discovery popup* (third style, repeated facts) -> story.
Now: cleaning -> **Catalogue Entry** (one screen, actions CONTINUE / WATCH STORY) -> story only if chosen.

### Created
- `scripts/ui/components/catalogue_stamp.gd` (`CatalogueStamp`): the "cataloguing" press-in mark (3 px rule, hard 4,4 shadow, check icon + word; instant with reduced motion).
- `scripts/test_phase5_discovery_ui.gd`: all 25 entries fit 1280x720 / no raw markup / integer years; ARCHIVE vs FIELD READINGS present; signal order; input guard; reduced motion; excavation prompt font sizes; HUD popup removed.
- `scripts/qa/phase5_screens.gd`: renders excavation / cleaning 0-50-100 % / catalogue screenshots in one run.

### Rewritten
- `scripts/ui/scientific_examination_panel.gd` -> **Catalogue Entry** (path kept for artifact.gd and tests).
  Gold rule; category + entry index (`MOON · 03 / 07`, same numbering as the journal); name (28 px) + stamp; data row (mission · year · status);
  left **ARCHIVE RECORD** (purpose, size, account, sources; gold badge) | right **FIELD READINGS · IN-GAME** (stratum, depth, signal, measured, estimated, setting; red SIM badge).
  No fact is repeated. Missing data is hidden: the old code printed an invented 12.0 cm depth for the 11 artifacts that have no `discovery_depth_cm`.
  Esc / E / Enter are taken in `_input`; ignored for 0.8 s so a held E cannot skip the screen; WATCH STORY has initial focus.
- `scripts/ui/excavation_menu.gd`: translucent `HudPanel` in the same bottom-centre prompt zone as `WorldHud.show_prompt`; 14+ px; key-caps from the InputMap;
  one primary action (`PrimaryButton`), secondary and cancel (`GhostButton`); SIM badge on the depth/signal line. Esc is consumed in `_input`
  (before the HUD opens pause and the player releases the mouse). E/Q keep their old `_unhandled_input` timing so the dig hand-over is unchanged.

### Changed
- `scripts/ui/dig_clean_ui.gd`, `scenes/ui/dig_clean_ui.tscn`: tool row (brush glyph + IDLE/BRUSHING in words), neutral stage text
  (the old "Spacecraft structure emerging" was wrong for rocks), faint gamepad rumble while brushing, clearer copy.
- `scripts/artifact/artifact.gd`: the `Label3D` prompts are replaced by the HUD key-cap prompt (`_refresh_prompt`, shown only while the player is in the zone);
  `story_requested` is connected; `_on_documentation_closed` hands WATCH STORY to the HUD. `GameState` signals and artifact IDs untouched.
- `scripts/ui/hud.gd`, `scenes/ui/hud.tscn`: `DiscoveryPopup` (10 nodes) and its code removed; new `play_artifact_story()`; group `hud`;
  toast text is now "SPECIMEN STORED — name" (the entry itself says CATALOGUED); the mouse is made visible again after the mission-complete modal opens
  (artifact.gd recaptured it immediately, so the modal buttons could not be clicked).
- `scripts/ui/components/world_hud.gd`: joins group `world_hud`.
- `scripts/ui/components/archive_card.gd`: **bug fix** — `shadow_size = 0` draws no shadow in Godot; now 1, so the hard 4,4 offset actually renders.
- `documentation/INTERFACES.md`, `design-system/.../pages/catalogue-entry.md`: updated.

### Decisions you may want to revisit
- `_on_popup_closed()` stays on the HUD only because `test_artifact_video_system` calls it.
- The geology inspection system (`[F] Examine`) keeps its own `Label3D` prompt; it is a separate mini-system, not part of the dig -> story pipeline.
- Stamp says CATALOGUED when the entry opens; GameState registration happens when the entry closes (unchanged flow).

### Not done / limits
- Not run in Godot. Most likely first-run issues: autowrap label heights on the first layout frame (the card might need one frame to settle), and
  the 1040 px card width at 16:10 / very small windows (it is clamped to viewport - 96 px).
- Cleaning still draws a generic probe silhouette for every artifact; per-artifact silhouettes belong to Phase 6 (journal slots).
- No sound yet (Phase 8): stamp thump, brush loop.


## Phase 6 — Journal, gallery, inspector

**Verification status: NOT run in Godot** (no Godot binary in the authoring sandbox). Static checks done: every changed `.gd` file parses with `gdparse` (gdtoolkit 4.5), tab indentation, no removed-node references left (`journal_modal`, `JournalModal`, `moon_tab_btn`, ...).
Run first: `test_phase6_collection_ui` (new), `test_historical_spacecraft_assets` (uses the gallery and inspector), `test_phase5_discovery_ui`, `test_full_suite`, `test_lunar_terrain_and_gameplay`, `test_artifact_video_system`, `test_lunar_archaeology`.

### Result
The collection screens now use one language (ArchiveCard, Badge, KeyCap, SegmentedMeter, Theme buttons) and reward progress: numbered silhouette slots, per-category progress, informative locked slots, key facts first with the narrative behind READ MORE.

### Created
- `scripts/ui/components/journal_slot.gd` (`JournalSlot`): numbered slot with a drawn silhouette. Bauhaus shape per category (`shape_for()`: natural material = circle, scientific discovery = triangle, mission remnants = square, historical spacecraft = diamond, deep space probe = ring). Locked slot = dashed square + lock icon, "Subsurface anomaly", `MOON · UPPER LOOSE REGOLITH`. Focus and selection use a gold 2 px border (shape, not only colour); idle borders are PAPER_500 (>= 3:1).
- `scripts/ui/components/journal_drawer.gd` (`JournalDrawer`, layer `LAYER_MODALS`): planet tabs with found/total, a progress meter, category filter chips with found/total, a 2-column slot grid (scrolls), and a detail panel.
  - Found entry: category + `MOON · 03 / 07`, name (28 px), ARCHIVE + CATALOGUED badges, data row (mission, year, location), three key facts (purpose, status, size), READ MORE (historical account + sources), WATCH STORY (only when a story exists: documentary video or `data/flashbacks.json`).
  - Locked entry: "Subsurface anomaly", NOT CATALOGUED badge, location + stratum, how to find it. Never shows the name or the category.
  - Only the ARCHIVE record appears here; simulated in-game readings stay in the Catalogue Entry.
  - Selection follows focus, so arrow keys / D-pad browse and Enter is optional. Esc is consumed in `_input` (top modal closes first). Focus returns to the previous owner on close.
  - Mars tab: stays readable, shows a SURVEY LOCKED notice while Mars is locked.
- `scripts/test_phase6_collection_ui.gd`, `scripts/qa/phase6_screens.gd` (screenshots: empty, partial, read more, filter, locked detail, Mars, full, gallery, gallery + inspector).

### Rewritten
- `scripts/spacecraft/spacecraft_gallery.gd` UI: header (name, destination, `02 / 05`, Return + Esc cap), info panel on the right (launch, distance, status, why it matters; ARCHIVE badge), selector rail at the bottom (one toggle per craft, wraps; Previous / Next / Auto-rotate / Inspect with KeyCaps read from the InputMap). B4 stays fixed: nothing can leave the screen. Selection follows focus. The 3D view remains draggable (root ignores the mouse). While the inspector is open the rail and info panel step aside.
  - Raw `KEY_*` checks removed: input now uses `gallery_prev`, `gallery_next`, `gallery_inspect`, `gallery_rotate`, `ui_cancel`.
  - Public contract kept: `spacecraft_list`, `mount_point`, `current_craft_index`, `select_next_spacecraft()`, `select_prev_spacecraft()`, `toggle_component_inspector()`.
- `scripts/ui/spacecraft_inspector_hud.gd`: rebuilt from components (ArchiveCard, SegmentedMeter position meter, KeyCaps, Ghost / Primary buttons). Old blue 6 px panel, 12-18 px overrides, `•` bullet and colour literals are gone. Contract kept (see the test list in INTERFACES.md). Initial focus on "Next component".

### Changed
- `scenes/ui/hud.tscn`: `JournalModal` subtree and its two styles removed.
- `scripts/ui/hud.gd`: owns a `JournalDrawer` (`journal`); `toggle_journal()`, `_populate_journal(planet)` kept as thin wrappers; every close path ends in `_on_journal_closed()` (scanner back, mouse captured unless pause / completion is open). WATCH STORY from the journal calls `play_artifact_story()`.
- `scripts/input/input_setup.gd`: new actions `gallery_inspect` (I) and `gallery_rotate` (Space) plus optional gamepad bindings for the four gallery actions (LB / RB / Y / X). Registered at runtime as before; `project.godot` untouched.

### Decisions you may want to revisit
- `JournalDrawer.SPOILER_FREE = false`: category filters show found/total per category (this is the requested "progress per category"), so a filtered view lists locked slots of that category and thereby hints at their type. Set it to `true` to show only the found count and hide locked slots in filtered views.
- Number hotkeys 1-5 in the gallery were removed (raw keys). Use Previous / Next, Left / Right, or click the rail. Say so if you want `gallery_pick_1..5` actions.
- With a rail button focused, Space activates that button (ui_accept) before the `gallery_rotate` action can see it; use the Auto-rotate button or the gamepad X button there.
- In the inspector, Left / Right move focus between its buttons (standard focus navigation); Q / E (or the shoulder buttons) change the component directly.
- Journal still covers Moon and Mars only. The 5 "Solar System" entries belong to the gallery and are not collectable in the world.

### Not done / limits
- Not run in Godot. Most likely first-run issues: the journal card height at 1280x720 (fixed minimum `min(640, viewport - 64)`; the slot grid scrolls inside), and `HFlowContainer` filter chips wrapping on narrow windows.
- No real specimen imagery yet: silhouettes are generic shapes by category, not per-artifact drawings.
- Component gallery (`component_gallery.tscn`) does not yet list `JournalSlot`.
- Sound for tab / filter / selection changes belongs to Phase 8.


## Merge (integrated1 gameplay + this design system)
Harsh's phases above are history and are kept as written. What changed when the design system moved onto integrated1:
- **Added:** `RadarDial` inside `ScannerInstrument` (phase 3), fullscreen toggle + restart mission (phase 4), flashback skin (phase 8).
- **Replaced by integrated1 behaviour:** harsh's hold-to-brush cleaning timer -> manual mouse scrubbing on a dirt mask, with harsh's `SpecimenReveal` probe as the image underneath; harsh's excavation menu -> integrated1's one-press `[E]` dig mini-game.
- **Not ported:** documentary video player, spacecraft gallery + inspector (phase 6 gallery rows), Phase 8 sound work (stamp / brush loop; `CREDITS.md` still lists no UI sounds).
- **Thresholds:** scanner uses 65 / 4 / 15 / 35 m (harsh: 60 / 4 / 12 / 25).
- **Bugs found while merging** (all fixed, details per phase in `MERGE_LOG.md`): Settings / Field manual drawn behind pause; `is_modal_blocking()` counting every CanvasLayer; Mars button shortcut removed; WorldHud anchors; `get_meta` error spam; mouse not released after mission-complete.
- **Open:** HUD area is over the ~15 % target at 1280x720 (20.9 %) and 1366x768 (18.3 %); decide whether to shrink further.

