# Override — Journal (Phase 6, implemented)
Archive drawer (`JournalDrawer`) on layer 20: planet tabs with found/total, progress meter, category filter chips with found/total,
2-column grid of `JournalSlot`s, detail panel. Selection follows focus; Esc closes; focus returns to the opener.

**Slot:** `NN` (mono, gold when catalogued) + name + category caption + silhouette. Silhouette per category (Bauhaus shapes):
circle = natural material, triangle = scientific discovery, square = mission remnants, diamond = historical spacecraft, ring = deep space probe.
Catalogued slots carry a gold registration mark. Locked slots: dashed square + lock, "Subsurface anomaly", `PLANET · STRATUM`. No name, no category.

**Detail (found):** category + `MOON · 03 / 07`; name 28 px; ARCHIVE + CATALOGUED badges; mission / year / location row;
key facts: PURPOSE, STATUS, SIZE; READ MORE reveals historical account + sources; WATCH STORY only when a story exists.
**Detail (locked):** UNIDENTIFIED, NOT CATALOGUED badge, location + stratum, how to find it.

**Rules:** archive facts only (in-game readings live in the Catalogue Entry); state is never colour alone (shape + words);
idle control borders PAPER_500, selected / focused = 2 px gold; `SPOILER_FREE` decides whether filters reveal per-category totals.

# Override — Gallery and inspector (Phase 6)
Header card (name, destination, `02 / 05`), info card right (launch, distance, status, why it matters), selector rail bottom
(wraps, KeyCaps from the InputMap), inspector bottom card with a position meter. Rail and info step aside while the inspector is open.
