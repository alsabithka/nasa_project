class_name HeroBackdrop
extends Control

## Echoes Beyond Earth — HeroBackdrop
## Static, drawn (no textures, no motion): ink void, sparse stars, a lunar horizon arc,
## and a flat Earth disc (Bauhaus circle). Sits behind the main menu, left column stays clear.
## Pure _draw so it scales to any resolution and costs nothing per frame.

@export var star_count: int = 90
@export var seed_value: int = 1971

var _stars: Array[Vector3] = []   # x, y in 0..1, z = brightness 0..1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_stars.clear()
	for i in star_count:
		_stars.append(Vector3(rng.randf(), rng.randf() * 0.72, rng.randf()))
	resized.connect(queue_redraw)
	queue_redraw()


func _draw() -> void:
	var w: float = size.x
	var h: float = size.y
	draw_rect(Rect2(Vector2.ZERO, size), UITokens.INK_900)

	# Stars: 1–2 px squares, kept out of the left text column.
	for s in _stars:
		var x: float = s.x * w
		if x < w * 0.46 and s.y > 0.2:
			continue
		var a: float = 0.25 + 0.55 * s.z
		var px: float = 2.0 if s.z > 0.8 else 1.0
		draw_rect(Rect2(x, s.y * h, px, px), Color(UITokens.PAPER_100, a))

	# Earth: flat disc, cyan rim, offset right of centre.
	var earth_c := Vector2(w * 0.76, h * 0.30)
	var earth_r: float = minf(w, h) * 0.12
	draw_circle(earth_c, earth_r, UITokens.INK_700)
	draw_arc(earth_c, earth_r, 0.0, TAU, 96, UITokens.SIGNAL_CYAN, 2.0, true)
	# One terminator band so it reads as a sphere, not a coin.
	draw_arc(earth_c, earth_r * 0.62, -0.9, 0.9, 48, Color(UITokens.SIGNAL_CYAN, 0.55), 1.0, true)

	# Lunar horizon: big arc, filled below.
	var horizon_c := Vector2(w * 0.60, h * 1.95)
	var horizon_r: float = h * 1.38
	var pts := PackedVector2Array()
	var steps: int = 64
	for i in steps + 1:
		var ang: float = lerpf(PI * 1.12, PI * 1.88, float(i) / float(steps))
		pts.append(horizon_c + Vector2(cos(ang), sin(ang)) * horizon_r)
	var fill := PackedVector2Array(pts)
	fill.append(Vector2(w + 4.0, h + 4.0))
	fill.append(Vector2(-4.0, h + 4.0))
	draw_colored_polygon(fill, UITokens.INK_800)
	draw_polyline(pts, UITokens.PAPER_500, 2.0, true)

	# Survey grid on the surface: thin rules fanning toward the horizon (structure, not decoration).
	var vp := Vector2(w * 0.60, h * 0.56)
	for i in range(-6, 7):
		var bx: float = w * 0.60 + float(i) * w * 0.16
		draw_line(vp, Vector2(bx, h), Color(UITokens.INK_600, 0.55), 1.0)
