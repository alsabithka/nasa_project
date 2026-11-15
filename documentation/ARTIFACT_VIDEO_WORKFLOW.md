# Artifact Documentary — Workflow & Reference

How to turn NASA source links into a finished artifact documentary that plays in the game.
Design rules live in `ARTIFACT_VIDEO_TEMPLATE.md`.

---

## 1. Pipeline at a glance

```
NASA links + media you provide
      │
      ▼
 1 Source brief ──► 2 Fact ledger ──► 3 Narration + storyboard ──► 4 Picture/sound edit
                                                                        │
      ┌─────────────────────────────────────────────────────────────────┘
      ▼
 5 Render .ogv  ──► 6 Manifest entry (status "in_production" → "ready") ──► 7 Validate + play-test
```

At runtime nothing else is needed: the HUD opens `artifact_video_player.tscn`, which plays the video if the
manifest says it is `ready`, and otherwise shows the original text flashback.

---

## 2. What to give me for the next artifact

For each artifact, send a **source brief**. Copy this block and fill it in:

```markdown
## Source brief — <artifact_id>            (must match data/artifacts.json, e.g. apollo_lrv)

Planet: Moon | Mars        Artifact type: human_made | natural_specimen
Which exact object does the in-game artifact represent? (mission / unit / site):

### Sources (NASA first)
| ID | URL | What it is | What I want it used for |
|----|-----|------------|--------------------------|
| S1 | https://…  | e.g. NASA mission page | origin, purpose |
| S2 | https://…  | e.g. mission report / NTRS paper | key events, dates |
| S3 | https://…  | e.g. NASA Image & Video Library item | archival footage for chapter 4 |

### Media files I will supply (or have placed in assets/videos/<id>/source/)
| File | Source ID | Credit line to show |
|------|-----------|---------------------|

### Must include / must avoid
- Must include:
- Must avoid:

### Voice / length preferences (optional)
```

Practical notes:

- **Links:** NASA pages are best. Mission reports, NASA Technical Reports Server papers, JPL/NASA Science pages,
  and NASA Image & Video Library items all work. Say which link is the authority if sources disagree.
- **Media files:** URLs are used as *research and provenance*. They are not played by the game. In this
  workspace, outbound network access is restricted and NASA media cannot be downloaded from the build
  environment, so **footage, stills and audio have to be added to the project by you** (e.g. under
  `assets/videos/<id>/source/`), or be produced from them in your editor. Page text I can read when you paste
  the link in chat.
- **Multiple artifacts:** send one brief per artifact. The same template is reused every time.

### What I do with the brief

1. Read every supplied source and write the **fact ledger** (`claim | source | status`), where status is
   `documented`, `explained`, `estimate` or `uncertain`.
2. Compare it with `artifacts.json` / `flashbacks.json`, which are only **project context**, not verified
   sources. Conflicts are reported to you, not silently resolved.
3. Build the chronology and fill the six-chapter structure (merging/dropping chapters if the record is thin).
4. Write the narration script (word budget) and the storyboard, with a footage type and credit for every scene.
5. Produce the subtitle cues, lower thirds, footage classification, sources and attribution **as manifest data**.
6. List what is still missing (e.g. "no archival footage supplied for chapter 3 → needs reconstruction").

Things I will not do: invent dates, specs, quotes or events; present the in-game dig as a real NASA event;
claim a scene is archival when it is not.

---

## 3. Producing the video file

Edit in any video editor with the rendered picture and sound only (no subtitles/chapter cards burned in),
export a **1920×1080, 24 fps** master, then convert to Theora/Vorbis:

```bash
ffmpeg -i master.mp4 -r 24 -s 1920x1080 \
  -c:v libtheora -q:v 6 -pix_fmt yuv420p \
  -c:a libvorbis -q:a 4 \
  assets/videos/<artifact_id>/<artifact_id>.ogv

# duration to type into the manifest
ffprobe -v error -show_entries format=duration -of csv=p=0 assets/videos/<artifact_id>/<artifact_id>.ogv
```

`-q:v 6` is a good size/quality start; raise to 7–8 for quality, use `-s 1280x720` if files get too large.
Open the project in Godot once so the asset is registered (a `.uid` file appears next to it; commit it).

---

## 4. Manifest reference — `data/artifact_videos.json`

```jsonc
{
  "schema_version": 1,
  "settings": {                         // global, optional (defaults shown)
    "play_placeholder_videos": false,   // true = also play entries with status "placeholder" (dev preview)
    "pause_game_during_playback": true, // freeze the 3D world while the film plays
    "controls_autohide_sec": 3.0,
    "chapter_card_sec": 3.2,
    "end_card_sec": 8.0                 // 0 = skip the closing card
  },
  "series": { "name": "...", "tagline": "...", "closing_line": "..." },
  "videos": {
    "<artifact_id>": { ...entry... }    // key = existing id from artifacts.json
  }
}
```

### Entry fields

| Field | Req. | Description |
|---|---|---|
| `status` | ✅ | `ready` plays in the game · `placeholder` plays only if `play_placeholder_videos` is true · `in_production` never plays (text flashback is used) |
| `artifact_type` | | `human_made` or `natural_specimen` (documentation/analytics; not used for playback) |
| `title`, `subtitle` | ✅ title | Shown in the top band and on the closing card |
| `video` | ✅ | `res://assets/videos/<id>/<id>.ogv` (Ogg Theora only) |
| `duration_sec` | ✅ | Exact length from `ffprobe`. Godot can't read Theora length |
| `chapters[]` | ✅ | `{ "id", "title", "start", "number"? }`. `start` in seconds, strictly increasing. Any count; names are free |
| `subtitles[]` *or* `subtitles_file` | ready | Inline `{start, end, text}` cues, or `res://…/<id>.en.srt` |
| `lower_thirds[]` | | `{start, end, label, text}` |
| `footage[]` | ready | `{start, end, type, credit}`; `type` ∈ `archival`, `mission_animation`, `reconstruction`, `data_visual`, `gameplay`, `placeholder`. Cover the whole film |
| `sources[]` | ready | `{ "title", "url", "publisher", "used_for", "accessed" }` — URLs are provenance only |
| `source_status` | | Free notes: `nasa_resources_received`, `open_questions[]`, etc. Not shown to players |
| `attribution` | ready | `{ "credit_line": "...", "disclosures": ["..."] }` shown on the closing card |

### Status lifecycle

`in_production` → (file + data complete) → `ready`.
`placeholder` is only for template demos and tests.

---

## 5. Adding the next artifact — step by step

1. Provide the source brief (§2).
2. After research and storyboard approval, produce the `.ogv` and subtitles.
3. Put the file at `assets/videos/<id>/<id>.ogv`.
4. Add `videos["<id>"]` to `data/artifact_videos.json` (copy the `apollo_lrv` entry as a starting shape).
5. Run the validation test:
   ```bash
   godot --headless --path . -s res://scripts/test_artifact_video_system.gd
   ```
   It validates **every** manifest entry: file exists, `.ogv`, chapters in order, cues inside the duration,
   footage typed and credited, and — for `ready` entries — sources with URLs, subtitles, no placeholder
   footage/text, and an attribution credit line.
6. Set `"status": "ready"` only when validation passes and the fact ledger is signed off.

No code changes are required to add an artifact. `artifact.gd`, `hud.gd` and `GameState` are not touched.

---

## 6. How playback connects to discovery

```
Scanner → dig / clean artifact → GameState.register_artifact(id)
  → GameState.artifact_recovered(id) → HUD shows discovery popup
  → player clicks Close → HUD._trigger_flashback(id)
        → instantiates scenes/ui/artifact_video_player.tscn  (artifact_id = id)
              ├─ manifest entry "ready" & file importable → documentary plays
              │     Space/K pause · C captions · Esc/Enter or SKIP skips · click picture pauses
              │     video ends → closing card (sources, credits) → auto-continue / CONTINUE
              └─ otherwise → original text flashback (scenes/ui/flashback.tscn) runs inside the player
        → playback_complete(artifact_id, "completed" | "skipped" | "fallback")
  → HUD._on_flashback_complete() recaptures the mouse and exploration resumes
```

- Works for Moon and Mars; it only needs the artifact id.
- The 3D world is paused during a video (configurable) and unpaused when it ends, is skipped or is freed.
- If a video fails to load or decode, the player silently falls back to the text flashback.
- `data/flashbacks.json` remains the safety net for every artifact without a finished film.

### Previewing a placeholder in the real game flow

Set `"play_placeholder_videos": true` under `settings`, discover the Apollo LRV, close the popup.
Turn it back to `false` for normal play.

---

## 7. Known limitations

- **Theora only.** It is the only video format Godot plays natively; other formats were not evaluated here.
- **No seeking.** Godot's Theora playback cannot seek, so the progress bar and chapter ticks are display-only.
  Players can pause, skip the entire film, or toggle captions.
- **Duration is manual** (`duration_sec`), because Theora length is not exposed at runtime.
- **File size.** 1080p Theora is large; consider Git LFS for `.ogv`.
- **Audio levels** are not adjustable inside the player yet.
- **Localization** is possible (swap `.srt` per language) but only English is wired.
- **Headless tests cannot judge picture or sound quality.** Visual review requires running the game.
