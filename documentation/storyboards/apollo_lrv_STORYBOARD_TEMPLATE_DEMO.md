# Storyboard — Apollo Lunar Roving Vehicle (`apollo_lrv`)

> **TEMPLATE DEMONSTRATION — NOT A FINISHED DOCUMENTARY.**
> No NASA sources have been supplied yet. This file shows how the master template is applied to one artifact.
> Every `⟦…⟧` is a slot to be filled **from supplied NASA sources**. Nothing below is a historical claim.

Playable stand-in: `assets/videos/apollo_lrv/apollo_lrv_placeholder.ogv` (24 s test card) with the matching
placeholder entry in `data/artifact_videos.json` (`status: "placeholder"`, so it never plays in normal gameplay).

---

## 1. Status of research

| Item | State |
|---|---|
| NASA resources supplied | **No** |
| Fact ledger | Empty — to be written from sources |
| Project context available | `data/artifacts.json`, `data/flashbacks.json` (**unverified**, see §2) |
| Footage supplied | None |

## 2. Project-context claims that must be confirmed (or corrected) against NASA sources

The repository's existing text is *not* treated as evidence. Before any of it is narrated it needs a source:

| Where | Claim in the repo | Status |
|---|---|---|
| `artifacts.json` history | Built by Boeing and Delco | ❓ unverified |
| `artifacts.json` history | Allowed astronauts to travel up to 35 km from the lunar module | ❓ unverified |
| `artifacts.json` mass/dimensions | 210 kg, 310 × 206 × 114 cm | ❓ unverified (may be gameplay values) |
| `flashbacks.json` scene 1 | Apollo 15, 31 July 1971, Hadley-Apennine region, LM "Falcon" | ❓ unverified |
| `flashbacks.json` scene 2 | Scott & Irwin, 27.9 km traverse, "Genesis Rock", core samples | ❓ unverified |
| `flashbacks.json` scene 3 | Three LRVs remain on the Moon (Taurus-Littrow, Descartes, Hadley-Apennine) | ❓ unverified |
| `artifacts.json` gameplay fields | `measured_properties`, `estimated_properties`, `discovery_depth_cm`, `stratigraphic_layer`, `detection_signature` | 🎮 **gameplay values — never narrate** |

**Open question for the next step:** `artifacts.json` lists the mission as *Apollo 15, 16, 17* but places the
in-game vehicle at *Taurus-Littrow* (the Apollo 17 site). The film must decide which vehicle's story it tells —
one specific LRV, or the program as a whole — and say so on screen. Please confirm with the sources.

## 3. Sources needed (to be supplied)

| Chapter | Kind of NASA source that would answer it |
|---|---|
| 01 Origin | Program history / development documents; contractor and design-team information |
| 02 Purpose | Mission planning documents describing why surface mobility was needed |
| 03 Journey | Launch/landing/deployment records for the specific mission |
| 04 Moments | Mission reports, traverse and science-result summaries, mission film/photos |
| 05 Final chapter | Records of where the vehicle was left and why |
| 06 Legacy | Present-day NASA/LRO imagery or histories of the site and the vehicle's influence |

## 4. Storyboard (template applied)

Total target: ⟦90–150 s⟧ · demo placeholder: 24 s (6 chapters × 4 s)

| # | Time | Chapter | Narration (exact) | Visual | Footage type | Credit | Lower third | Fact status |
|---|---|---|---|---|---|---|---|---|
| 1 | 0:00–0:04 | 01 The Origin | ⟦cold open fact about the vehicle's creation⟧ | ⟦archival photo of development/test⟧ | `archival` | ⟦NASA/…⟧ | `PROGRAM · YEAR` ⟦…⟧ | ⟦documented⟧ |
| 2 | 0:04–0:08 | 02 Its Purpose | ⟦the problem mobility had to solve⟧ | ⟦mission planning diagram or film⟧ | `data_visual` / `archival` | ⟦…⟧ | | ⟦documented⟧ |
| 3 | 0:08–0:12 | 03 The Journey | ⟦how it travelled to the Moon and was deployed⟧ | ⟦launch / stowage / deployment film; reconstruction only where no film exists⟧ | `archival` / `reconstruction` | ⟦…⟧ | `MISSION · DATE` ⟦…⟧ | ⟦documented⟧ |
| 4 | 0:12–0:16 | 04 Its Most Important Moments | ⟦documented traverses and science results⟧ | ⟦surface film; route map⟧ | `archival` + `data_visual` | ⟦…⟧ | `MISSION EVENT` ⟦…⟧ | ⟦documented / estimate⟧ |
| 5 | 0:16–0:20 | 05 The Final Chapter | ⟦where and how it was left⟧ | ⟦last film/photo of the parked vehicle⟧ | `archival` | ⟦…⟧ | | ⟦documented⟧ |
| 6 | 0:20–0:24 | 06 Its Legacy | ⟦why it still matters⟧ | ⟦present-day orbital imagery; vehicle in game for context⟧ | `archival` / `gameplay` | ⟦…⟧ | | ⟦documented / explained⟧ |

In the finished film, each chapter will hold several shots (see template §5), not one.

## 5. What the demo placeholder exercises

| Template element | Where it appears in the demo |
|---|---|
| Top band: brand, artifact title, chapter indicator | Always visible during playback |
| Chapter title cards (6) | At 0, 4, 8, 12, 16, 20 s |
| Chapter ticks on progress bar | Five ticks |
| Subtitles (`[PLACEHOLDER]` text) | One per chapter; `C` / CC button toggles |
| Lower thirds | At 1.0 s and 13.0 s |
| Footage badge | Amber `PLACEHOLDER · Generated test card — not NASA material` |
| Closing card | Title, subtitle, "No sources listed", disclosures, series closing line |
| Pause / skip / auto-continue | Space·K, click, SKIP, Esc·Enter |
| Fallback | With `play_placeholder_videos: false` the text flashback runs instead |

## 6. To turn this into the real film

1. Supply the NASA source brief for `apollo_lrv` (see `ARTIFACT_VIDEO_WORKFLOW.md` §2).
2. Resolve the open question in §2.
3. Fact ledger → narration → storyboard approval → edit → render `.ogv`.
4. Replace the placeholder manifest entry (real chapters, subtitles, footage, sources, attribution,
   `status: "ready"`) and delete `apollo_lrv_placeholder.ogv`.
