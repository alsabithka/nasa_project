class_name Badge
extends PanelContainer

## Echoes Beyond Earth — Badge Component
## Small status tag. Status is NEVER colour alone: every kind carries an icon + text.
##   kind ARCHIVE  = documented NASA record      (gold)
##   kind SIM      = simulated in-game reading   (red, dashed-box icon)
##   kind LIVE     = live telemetry              (cyan)
##   kind OK       = confirmed / catalogued      (green, check)
##   kind LOCKED   = not yet available           (grey, lock)
## Usage: var b := Badge.make(Badge.Kind.SIM)   or   b.kind = Badge.Kind.OK; b.text = "CATALOGUED"

enum Kind { ARCHIVE, SIM, LIVE, OK, LOCKED }

@export var kind: Kind = Kind.ARCHIVE : set = set_kind
@export var text: String = "" : set = set_text

var _icon: TextureRect
var _label: Label

const _DEFAULTS := {
	Kind.ARCHIVE: ["archive", "ARCHIVE RECORD"],
	Kind.SIM:     ["sim",     "SIM"],
	Kind.LIVE:    ["signal_faint", "LIVE"],
	Kind.OK:      ["check",   "CATALOGUED"],
	Kind.LOCKED:  ["lock",    "LOCKED"],
}

static func make(k: Kind, custom_text: String = "") -> Badge:
	var b := Badge.new()
	b.kind = k
	b.text = custom_text
	return b

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UITokens.SP_1 + 2)
	row.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(row)
	_icon = UITokens.make_icon("check", UITokens.PAPER_100, 12)
	row.add_child(_icon)
	_label = Label.new()
	_label.theme_type_variation = &"CaptionLabel"
	_label.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(_label)
	_refresh()

func set_kind(v: Kind) -> void:
	kind = v
	if is_inside_tree(): _refresh()

func set_text(v: String) -> void:
	text = v
	if is_inside_tree(): _refresh()

func _accent() -> Color:
	match kind:
		Kind.ARCHIVE: return UITokens.SIGNAL_GOLD
		Kind.SIM:     return UITokens.SIGNAL_RED
		Kind.LIVE:    return UITokens.SIGNAL_CYAN
		Kind.OK:      return UITokens.SIGNAL_GREEN
		_:            return UITokens.PAPER_500

func _refresh() -> void:
	var d: Array = _DEFAULTS[kind]
	_icon.texture = UITokens.icon(d[0])
	_label.text = text if text != "" else d[1]
	var c := _accent()
	_icon.modulate = c
	_label.add_theme_color_override("font_color", c)
	var sb := StyleBoxFlat.new()
	sb.bg_color = UITokens.INK_900
	sb.border_color = c
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(UITokens.RADIUS_PANEL)
	sb.content_margin_left = 8.0
	sb.content_margin_right = 8.0
	sb.content_margin_top = 3.0
	sb.content_margin_bottom = 3.0
	add_theme_stylebox_override("panel", sb)
