# Echoes Beyond Earth — Artifact Documentary Template

The master production standard for every artifact documentary. Each film is its own story, but all of them
must feel like episodes of one series: *Echoes Beyond Earth — Artifact Archive*.

How to use this document:

- This file = **how a documentary looks, sounds, is structured and is credited.**
- `ARTIFACT_VIDEO_WORKFLOW.md` = **how to take NASA sources → finished video → working in the game.**
- `storyboards/apollo_lrv_STORYBOARD_TEMPLATE_DEMO.md` = **the template applied to one artifact (placeholder content only).**

---

## 1. Guiding principles

1. **Storytelling, not slides.** Every film follows one object through a history: origin → purpose → journey →
   defining moments → ending → legacy. If a scene could be replaced by a paragraph of text, redesign it.
2. **Truth before drama.** No invented events, dates, specifications, quotes, discoveries or dialogue. Ever.
3. **Show how we know.** Every scene is one of four kinds of statement, and the viewer can tell which:

   | Kind | Meaning | How it is shown |
   |---|---|---|
   | **Documented fact** | Stated in a supplied NASA/primary source | Plain narration, source on closing card |
   | **Scientific explanation** | Mechanism supported by the sources (e.g. how a rock forms) | Narration phrased "scientists have concluded…" |
   | **Estimate / interpretation** | Measured range, model, or inference | Narration says "about / estimated / scientists believe"; lower third label `ESTIMATE` |
   | **Reconstruction** | Our own animation/3D/illustration | Footage badge `RECONSTRUCTION` (amber) for the whole scene |

4. **The game's fiction stays in the game.** Excavating the artifact is gameplay. Never present the player's
   in-game dig as a real NASA event. `measured_properties`, `estimated_properties`, `discovery_depth_cm`,
   `stratigraphic_layer` and similar fields in `artifacts.json` are gameplay values — never narrate them as fact.
5. **Uncertainty is allowed on screen.** "NASA records do not say" is a better line than a plausible guess.
6. **Authentic vs. made-up is always visible.** Archival footage and our reconstructions never share a scene
   without the badge changing.

---

## 2. Video identity

**Positioning:** a NASA historical documentary seen through the eyes of a space archaeologist.
Scientific exploration · historical preservation · planetary science · human achievement · the quiet mystery of
objects left beyond Earth.

**Tone of narration:** calm, precise, humane. Short declarative sentences. Present tense for what the object *is*
now, past tense for what *happened*. Wonder comes from the facts, not from adjectives. Avoid: "incredible",
"amazing", "epic", marketing language, rhetorical questions in every scene, and anything that sounds like a promo.

**Do not make it look like:** a slideshow, a PowerPoint template, a YouTube explainer, an AI promo reel, or a
news ticker. No spinning logos, glitch transitions, lens-flare stings, or stock "space" loops.

### 2.1 Palette (taken from the existing game UI)

| Role | Colour | RGB (0–1) | Hex | Used for |
|---|---|---|---|---|
| Void background | Near-black navy | 0.015, 0.02, 0.035 | `#040509` | Fades, end card, letterbox |
| Panel | Deep navy | 0.04, 0.05, 0.08 | `#0A0D14` | Lower thirds, bars |
| **Historical gold** | Gold | 0.98, 0.78, 0.20 | `#FAC733` | Chapter numbers, brand, historical labels, progress |
| Gold border | Soft gold | 0.95, 0.75, 0.20 | `#F2BF33` | Rules, panel borders |
| **Science cyan** | Light blue | 0.50, 0.80, 1.00 | `#80CCFF` | Scientific data, authentic-footage credit |
| Reconstruction amber | Amber | 1.00, 0.65, 0.20 | `#FFA633` | `RECONSTRUCTION` / `PLACEHOLDER` badge, section headers |
| Muted text | Grey-blue | 0.65, 0.70, 0.80 | `#A6B3CC` | Secondary text |

Grade the footage itself neutrally and truthfully — do not tint archival film gold or blue. The palette belongs
to the **overlays**, not to the historical material.

### 2.2 Typography and graphic motifs

- Overlays render with Godot's default UI font (same as the rest of the game). Any text baked into the video
  (see §8) should use a clean humanist sans-serif in white or gold; no script or sci-fi display fonts.
- Gold thin rules (3 px) under chapter numbers; thin 1–2 px gold borders; no drop shadows heavier than the
  outline already used by the player.
- Motifs allowed: scanner-style ring/crosshair on the artifact's position, thin map grid, mission-date counters,
  subtle telemetry-style numerals. Use sparingly and only when they carry information.

### 2.3 Brand marks

- **Series mark:** the words `ECHOES BEYOND EARTH` in gold (top-left of the player, always).
- **Series tagline:** `ARTIFACT ARCHIVE DOCUMENTARY SERIES` (cyan, closing card).
- **Series closing line:** set once in `data/artifact_videos.json → series.closing_line`.

---

## 3. Video specifications

| Item | Standard |
|---|---|
| Aspect ratio | **16:9** (the player letterboxes automatically in other window shapes) |
| Resolution | **1920 × 1080** master. Delivery may be 1280 × 720 if file size demands it |
| Frame rate | **24 fps** (use 24 for everything, including archival conversions) |
| Container / codec | **Ogg Theora video + Vorbis audio, `.ogv`** — the format Godot plays natively (verified on 4.7.2). H.264/MP4 will **not** play |
| Duration | **90–150 s** default. Shorter or longer as the history requires; never pad |
| Audio | Stereo, 44.1 kHz. Narration clear and forward; music bed ducked ≥ 10 dB under narration |
| Burned-in text | **None** for subtitles, chapter cards, sources (the game draws these from data). Baked-in titles only as listed in §8 |
| Delivery location | `assets/videos/<artifact_id>/<artifact_id>.ogv` |
| Safe area | Keep the primary subject between **8 % and 72 %** of frame height. The top 7 % (header band) and bottom ~28 % (lower third, subtitles, control bar) are covered by overlays |
| File size guidance | Theora is bulky. Expect tens of MB for 2 minutes of 1080p. Track `.ogv` files with Git LFS or keep them out of the repo if the team prefers |

Because Godot cannot read Theora length or seek, **the exact duration must be typed into the manifest**
(`duration_sec`, from `ffprobe`). See the workflow document.

---

## 4. Storytelling structure

Six chapters, adaptable. Chapter titles and count live in the manifest and can be renamed, merged or dropped.
Chapter-card numbers appear automatically.

| # | Default title | Question it answers |
|---|---|---|
| 01 | The Origin | Where, when and by whom (or what process) did this come into being? |
| 02 | Its Purpose | What problem was it for? What objective or natural process does it represent? |
| 03 | The Journey | How did it reach where it is now? |
| 04 | Its Most Important Moments | What happened to it / because of it? **The centre of the film.** |
| 05 | The Final Chapter | What ended its working life, or what is its resting condition? |
| 06 | Its Legacy | Why does it still matter, and what does it teach us? |

Suggested time budget for a 120 s film: 15 / 15 / 20 / 35 / 15 / 20 seconds. Chapter 4 is the longest.

### 4.1 Adapting the structure by artifact type

| Artifact type (`artifact_type`) | Examples | Adaptation |
|---|---|---|
| `human_made` — surface hardware | `apollo_lrv`, `alsep`, `apollo_lm_descent_stage`, `apollo_cable_bracket` | Full six chapters. Origin = engineering/contractors/program context from sources. Journey = launch/landing/deployment as documented |
| `human_made` — robotic spacecraft | `sojourner`, `opportunity`, `ingenuity`, `spirit`, `viking_1`, `phoenix`, `insight`, `pathfinder`, … | Full six chapters. Chapter 4 follows the mission timeline with dated science results. Chapter 5 = how contact/operations ended **as stated in sources** |
| `human_made` — deep-space probes | `pioneer_10`, `pioneer_11`, `dawn`, `kepler`, `near_shoemaker` | Journey is a trajectory story (maps, orbital visuals). Final chapter may be "still travelling" / last contact |
| `natural_specimen` — rocks, glass, meteorites | `lunar_ferroan_anorthosite`, `pyroclastic_orange_glass`, `martian_meteorite_shergottite`, `seitah_olivine_basalt`, `jezero_delta_clay` | Origin = formation. Purpose → **"What it is / what it records"** (no invented intent). Journey = geological or impact history **as supported**. Chapter 4 = how it was recognised/studied. **Chapter 5 is usually dropped or becomes "Where it rests"** — do not invent an ending |
| `human_made` — NASA remnants that are not spacecraft proper | `perseverance_heatshield_remnant` | Treat as hardware: purpose within a mission sequence, journey, what happened to the piece, current status |

When the record is thin, make the film **shorter**, not more imaginative.

---

## 5. Scene composition

- **Opening a chapter:** begin on an image that *shows* the chapter's subject before any text appears. The
  runtime chapter card fades in over it at the chapter's start time (0.6 s in, ~3 s hold, 0.8 s out) — leave the
  left-centre of the frame calm for it.
- **Pacing:** average shot 4–8 s. Archival stills get a slow, purposeful move (push-in or pan along the
  subject) held 6–10 s. Mission film runs as long as the content is interesting.
- **Subject variety across a film:** wide context → mid → detail. At least one *artifact close-up or 3D turn*
  and one *map/timeline/orbital* shot per film where sources support it.
- **Visual sources, in order of preference:**
  1. Authentic archival NASA film/photos/audio relevant to the sentence being spoken.
  2. Mission animations produced by NASA/JPL.
  3. Our 3D reconstructions and Echoes Beyond Earth gameplay capture (clearly badged).
  4. Maps, timelines, diagrams.
  Never use unrelated stock footage or "generic space" visuals to fill time.
- **Reconstructions:** show only what sources support; keep sequences simple; same camera language as archival
  (no impossible swoops); badge for the full duration of the scene.
- **Showing the game:** brief capture of the artifact in its in-game setting is allowed for context, badged
  `GAMEPLAY CAPTURE`, and never used to imply a historical event.
- **Numbers on screen:** only figures that appear in the sources, with their source named in the narration or
  lower third.

### Lower thirds (runtime, from `lower_thirds`)

Gold label (small caps) + white text. Use for: location, mission date, mission elapsed time, the `ESTIMATE` tag,
who/what is shown. Max ~60 characters of text. Show for 2.5–4 s. No more than one every ~6 s.

---

## 6. Narration format

- Write narration in a table before editing (Appendix B). One line = one idea = one picture.
- **Word budget:** ~2.3–2.6 words per second of speech. A 120 s film carries roughly 220–300 words of narration;
  leave silence for archival audio and music.
- **Attribution phrasing:** "According to NASA records…", "Mission reports describe…", "Scientists estimate…".
- **Quotes:** only verbatim, from a supplied source, with the speaker and source named. No paraphrase inside
  quotation marks. No invented radio chatter or dialogue.
- **Never** state a date, number, name or sequence you cannot point to in a supplied source.
- **Uncertainty phrasing:** "NASA records do not say…", "The exact … is not documented in the supplied sources."
- The first line of a film should earn attention with a *fact*, not a flourish. The last line should land the
  legacy (what the object teaches us) without a slogan.

---

## 7. Subtitle style

Subtitles are drawn by the game from the manifest (inline `subtitles` or an `.srt` file), so they can be toggled
(`C` or the CC button), re-timed and translated without re-rendering video.

| Property | Standard |
|---|---|
| Content | Verbatim narration (for archival speech, add the speaker in the cue, e.g. `ASTRONAUT NAME: …` only if sourced) |
| Look | 24 px white, black outline, on a translucent black rounded panel, centred above the control bar |
| Length | Max **2 lines**, ≈ 42 characters per line, ≤ 7 s on screen, ≥ 1 s |
| Timing | Cue starts ≈ 0.1 s after the voice begins, ends ≈ 0.2 s after it finishes |
| Gaps | No cue during silence/music-only moments |

---

## 8. What is baked into the video vs. drawn by the game

| Element | Baked into video | Drawn by game (data-driven) |
|---|---|---|
| Opening series sting (≤ 3 s, brand wordmark on black/space) | ✅ | |
| Cold-open and all picture, music, narration, archival sound | ✅ | |
| Artifact title card in the opening | optional (bake title only; never the date) | Top band shows brand + artifact title always |
| Chapter title cards | | ✅ `chapters` |
| Chapter indicator (`CHAPTER 02 / 06 · ITS PURPOSE`) + ticks on progress bar | | ✅ |
| Subtitles | | ✅ `subtitles` / `.srt` |
| Lower thirds (location, date, estimate, event) | | ✅ `lower_thirds` |
| Footage-type badge + credit (`ARCHIVAL FOOTAGE · NASA/…`) | | ✅ `footage` |
| Closing card: sources, credit line, disclosures, series closing line | | ✅ `sources`, `attribution`, `series` |
| Final fade to dark (last ~1 s) | ✅ | |

Rule of thumb: **words and credits live in data; pictures and sound live in the video.**

---

## 9. Transitions

- Film begins with a slow fade up from black (the player also fades in over 0.8 s — start the render on a
  near-black frame so they combine smoothly).
- Between shots in the same chapter: **cut** or a **0.5–1.0 s dissolve**.
- Between chapters: a gentle dip toward dark (≈ 0.5 s) or a held establishing shot. The chapter card handles
  the "title" — no extra wipe.
- Never: whip pans, zooms with motion blur, glitch, light leaks, spinning cubes, bouncing text.
- Film ends with a ≈ 1 s fade to black; the game then shows the closing card.

---

## 10. Sound design

- **Music:** restrained, cinematic, slow-moving; no vocals. One cue per film that can build through chapter 4
  and settle in chapter 6. Duck ≥ 10 dB under narration. Music must be licensed or original — document it in
  `attribution.disclosures` if it is not NASA material.
- **Narration:** one consistent voice across the series (neutral, warm, measured). Record or generate at a
  consistent loudness; disclose synthetic narration in `attribution.disclosures`.
- **Archival audio:** use only where sourced and relevant. Do not fabricate cockpit/radio audio.
- **Effects:** subtle room tone / vacuum-silence beats for lunar scenes, gentle atmospheric bed for Mars. Use
  silence as a design element in the final chapter.
- No sound sting on chapter changes (the player has none).

---

## 11. Source attribution

Three layers, all data-driven:

1. **In-picture:** every `footage` segment names its type and credit
   (`ARCHIVAL FOOTAGE · NASA/Johnson Space Center`). Reconstructions/placeholders show in amber.
2. **Closing card:** lists every `sources` entry (title + publisher) and the `attribution.credit_line` and
   `attribution.disclosures` (e.g. "Scenes in chapter 3 are our reconstruction", "Narration is synthetic",
   "Music: …").
3. **Metadata:** each source keeps its **URL**, publisher, what it supports (`used_for`) and access date in the
   manifest. NASA URLs are provenance — the game never streams them.

Credit-line pattern:
`Historical imagery and mission records courtesy of NASA. Reconstructions by Echoes Beyond Earth are marked.`
(Adjust to match what was actually used; check each asset's own credit and NASA's media-use guidance, and never
imply NASA endorsement.)

---

## 12. Opening sequence (≈ 8–12 s)

1. **Cold open (3–5 s):** one arresting, true image tied to the artifact (the object in situ, mission film, or
   the world it sits on). Ambient sound; no narration yet.
2. **Series sting (≤ 3 s):** `ECHOES BEYOND EARTH` wordmark in gold, small `ARTIFACT ARCHIVE` line in cyan.
3. **Title:** artifact name, then location/date via lower third (`LOCATION · DATE`).
4. **Chapter 1 card** (automatic) and first narration line.

## 13. Closing sequence (≈ 10–14 s video + closing card)

1. **Legacy statement** over the strongest present-day image (the object as it rests, or the science it enabled).
2. **Final beat of silence** — music resolves, one last image holds.
3. **Fade to black (~1 s).**
4. **Closing card** (game): title, sources, credit line, disclosures, series closing line; auto-continues
   after `settings.end_card_sec` (8 s) or on **CONTINUE**.

---

## 14. Per-film deliverables

For artifact id `<id>`:

- [ ] Source brief (links + what each is for) — see workflow doc
- [ ] Fact ledger (claim → source → documented / explanation / estimate / uncertain)
- [ ] Narration script + subtitle cues (`.srt` or inline)
- [ ] Storyboard (Appendix A)
- [ ] Final render `assets/videos/<id>/<id>.ogv` (1920×1080, 24 fps, Theora/Vorbis)
- [ ] Manifest entry in `data/artifact_videos.json` with `status: "ready"` and passing validation
- [ ] Credits / licences for any non-NASA music, narration or imagery

---

## Appendix A — Storyboard table (copy per artifact)

| # | Time | Chapter | Narration (exact) | Visual | Footage type | Credit / source id | Lower third | Fact status | Notes |
|---|---|---|---|---|---|---|---|---|---|
| 1 | 0:00–0:05 | — | *(silence / ambience)* | | archival / reconstruction / … | | | | cold open |

Footage types: `archival`, `mission_animation`, `reconstruction`, `data_visual`, `gameplay`.
Fact status: `documented`, `explained`, `estimate`, `uncertain`, `n/a`.

## Appendix B — Narration script table

| Line | Words | Start | End | Narration | Source (S#) | Status |
|---|---|---|---|---|---|---|

Check before locking: words ÷ seconds ≈ 2.3–2.6; every line has an S# or is marked non-factual; no number,
date or name without a source.
