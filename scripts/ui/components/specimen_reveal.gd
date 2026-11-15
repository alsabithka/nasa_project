class_name SpecimenReveal
extends Control

## Echoes Beyond Earth — SpecimenReveal Component
## A vector specimen (generic probe schematic, drawn in code) covered by a layer of lunar dust.
## As `progress` rises 0→1 the dust cells fall away left-to-right with noise, so the player
## SEES the object emerge (replaces the old flat grey rectangle — audit item B5).
## `brushing` animates a brush marker at the cleaning front. All colours come from UITokens.

@export_range(0.0, 1.0) var progress: float = 0.0 : set = set_progress
@export var brushing: bool = false : set = set_brushing
@export var cols: int = 28
@export var rows: int = 11
@export var seed_value: int = 7

var _thr: PackedFloat32Array = PackedFloat32Array()
var _tone: PackedFloat32Array = PackedFloat32Array()
var _t := 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(420, 190)
	mouse_filter = MOUSE_FILTER_IGNORE
	_build_cells()

func set_progress(v: float) -> void:
	progress = clampf(v, 0.0, 1.0)
	queue_redraw()

func set_brushing(v: bool) -> void:
	brushing = v
	set_process(v)
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _build_cells() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_thr.resize(cols * rows)
	_tone.resize(cols * rows)
	for y in rows:
		for x in cols:
			var fx := float(x) / float(max(1, cols - 1))
			_thr[y * cols + x] = clampf(fx * 0.60 + rng.randf() * 0.24, 0.0, 0.84)  # max 0.84 so every cell is clear at 100%
			_tone[y * cols + x] = rng.randf()
	set_process(false)

func _draw() -> void:
	if _thr.is_empty():
		_build_cells()
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2.ZERO, size), UITokens.INK_900, true)
	_draw_specimen(w, h)
	_draw_dust(w, h)
	draw_rect(Rect2(Vector2.ZERO, size), UITokens.PAPER_500, false, 1.0)

func _draw_specimen(w: float, h: float) -> void:
	var c := Vector2(w * 0.5, h * 0.5)
	var u := minf(w / 420.0, h / 190.0)
	# solar wings
	for side in [-1.0, 1.0]:
		var x0: float = c.x + side * 48.0 * u
		var x1: float = c.x + side * 178.0 * u
		var r := Rect2(Vector2(minf(x0, x1), c.y - 26.0 * u), Vector2(absf(x1 - x0), 52.0 * u))
		draw_rect(r, UITokens.INK_600, true)
		draw_rect(r, UITokens.PAPER_500, false, 1.5)
		for i in range(1, 5):
			var gx := r.position.x + r.size.x * float(i) / 5.0
			draw_line(Vector2(gx, r.position.y), Vector2(gx, r.end.y), UITokens.PAPER_500, 1.0)
		draw_line(Vector2(r.position.x, c.y), Vector2(r.end.x, c.y), UITokens.PAPER_500, 1.0)
	# boom + dish
	draw_line(c + Vector2(0, -34 * u), c + Vector2(0, -74 * u), UITokens.PAPER_300, 2.0)
	draw_arc(c + Vector2(0, -78 * u), 14.0 * u, PI, TAU, 20, UITokens.PAPER_100, 2.0)
	# body (hexagonal bus)
	var body := PackedVector2Array([
		c + Vector2(-34, -30) * u, c + Vector2(34, -30) * u, c + Vector2(48, 0) * u,
		c + Vector2(34, 30) * u, c + Vector2(-34, 30) * u, c + Vector2(-48, 0) * u])
	draw_colored_polygon(body, UITokens.PAPER_300)
	draw_polyline(body + PackedVector2Array([body[0]]), UITokens.PAPER_100, 2.0)
	# gold thermal-blanket band + instrument port
	draw_rect(Rect2(c + Vector2(-30, -8) * u, Vector2(60, 16) * u), UITokens.SIGNAL_GOLD, true)
	draw_circle(c + Vector2(0, 0), 6.0 * u, UITokens.INK_900)
	# landing legs
	draw_line(c + Vector2(-34, 30) * u, c + Vector2(-58, 62) * u, UITokens.PAPER_300, 2.0)
	draw_line(c + Vector2(34, 30) * u, c + Vector2(58, 62) * u, UITokens.PAPER_300, 2.0)

func _draw_dust(w: float, h: float) -> void:
	var cw := w / float(cols)
	var ch := h / float(rows)
	var dust_a := UITokens.INK_600
	var dust_b := Color(0.36, 0.40, 0.46)
	for y in rows:
		for x in cols:
			var i := y * cols + x
			var a := 1.0 - clampf((progress - _thr[i]) / 0.16, 0.0, 1.0)
			if a <= 0.01:
				continue
			var col := dust_a.lerp(dust_b, _tone[i])
			col.a = a * 0.97
			# +0.5 overlap hides hairline seams between cells
			draw_rect(Rect2(x * cw, y * ch, cw + 0.5, ch + 0.5), col, true)
	if brushing and progress < 1.0:
		var fx := clampf(progress * 0.84 + 0.04, 0.0, 1.0) * w
		var wob := sin(_t * 14.0) * 8.0
		var icon := UITokens.icon("brush")
		if icon:
			draw_texture_rect(icon, Rect2(Vector2(fx - 12.0, h * 0.5 - 12.0 + wob), Vector2(24, 24)), false, UITokens.SIGNAL_GOLD)
