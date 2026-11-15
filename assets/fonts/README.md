# Echoes Beyond Earth — Fonts

Place font files here: `assets/fonts/`

## Recommended Typefaces (open-licence, Google Fonts OFL)

| Role | Family | Files needed | Google Fonts URL |
|------|--------|-------------|-----------------|
| UI body / headings | **IBM Plex Sans** | `IBMPlexSans-Regular.ttf`, `IBMPlexSans-Medium.ttf`, `IBMPlexSans-Bold.ttf` | https://fonts.google.com/specimen/IBM+Plex+Sans |
| Data / numerals | **IBM Plex Mono** | `IBMPlexMono-Regular.ttf`, `IBMPlexMono-Medium.ttf` | https://fonts.google.com/specimen/IBM+Plex+Mono |

**Alternative body font:** Archivo — https://fonts.google.com/specimen/Archivo

## Steps to Bundle

1. Download the `.ttf` files from Google Fonts.
2. Place them in this directory.
3. In Godot, import each file as **Font** (DynamicFont).
4. Create a `.import` for each or reference directly in the Theme resource.
5. Update `ui/theme/ebe_theme.tres` to reference the loaded fonts:
   ```
   [ext_resource type="FontFile" path="res://assets/fonts/IBMPlexSans-Regular.ttf" id="1"]
   [resource]
   default_font = ExtResource("1")
   ```
6. Add this to your `CREDITS.md`:
   ```
   IBM Plex Sans / IBM Plex Mono — © IBM Corporation, licensed under OFL 1.1
   ```

## Verify Glyph Coverage

Before shipping, confirm these glyphs are present:
- Degree symbol: `°`
- Subscript two: `₂`
- Middle dot: `·`
- Multiplication: `×`
- En-dash: `–`
- Ellipsis: `…`
