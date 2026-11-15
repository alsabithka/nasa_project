class_name ListRow
extends PanelContainer

## Echoes Beyond Earth — ListRow Component
## One selectable row: [icon] title / subtitle ........ [trailing text or badge].
## Keyboard: focusable, Enter/Space (ui_accept) activates. Hover/focus/selected states differ in
## border + fill (not colour alone). Locked rows are dimmed, still focusable so they can be read.

signal activated

@export var title: String = "" : set = set_title
@export var subtitle: String = "" : set = set_subtitle
@export var trailing: String = "" : set = set_trailing
@export var icon_name: String = "" : set = set_icon_name
@export var locked: bool = false : set = set_locked
@export var selected: bool = false : set = set_selected

var _icon: TextureRect
var _title: Label
var _sub: Label
var _trail: Label
var _hover := false
var _focused := false

func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size.y = 52
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", UITokens.SP_3)
	row.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(row)
	_icon = UITokens.make_icon("check", UITokens.PAPER_300, 20)
	row.add_child(_icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 0)
	col.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(col)
	_title = Label.new()
	_title.theme_type_variation = &"LeadLabel"
	_title.mouse_filter = MOUSE_FILTER_IGNORE
	_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(_title)
	_sub = Label.new()
	_sub.theme_type_variation = &"CaptionLabel"
	_sub.mouse_filter = MOUSE_FILTER_IGNORE
	_sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(_sub)
	_trail = Label.new()
	_trail.theme_type_variation = &"StatLabel"
	_trail.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(_trail)
	mouse_entered.connect(func(): _hover = true; _style())
	mouse_exited.connect(func(): _hover = false; _style())
	focus_entered.connect(func(): _focused = true; _style())
	focus_exited.connect(func(): _focused = false; _style())
	_refresh()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		grab_focus()
		activated.emit()
		accept_event()
	elif event.is_action_pressed("ui_accept"):
		activated.emit()
		accept_event()

func set_title(v: String) -> void: title = v; _refresh()
func set_subtitle(v: String) -> void: subtitle = v; _refresh()
func set_trailing(v: String) -> void: trailing = v; _refresh()
func set_icon_name(v: String) -> void: icon_name = v; _refresh()
func set_locked(v: bool) -> void: locked = v; _refresh()
func set_selected(v: bool) -> void: selected = v; _refresh()

func _refresh() -> void:
	if _title == null:
		return
	_title.text = title
	_sub.text = subtitle
	_sub.visible = subtitle != ""
	_trail.text = trailing
	_trail.visible = trailing != ""
	_icon.visible = icon_name != ""
	if icon_name != "":
		_icon.texture = UITokens.icon("lock" if locked else icon_name)
	_title.add_theme_color_override("font_color", UITokens.PAPER_500 if locked else UITokens.PAPER_100)
	_icon.modulate = UITokens.PAPER_500 if locked else (UITokens.SIGNAL_GOLD if selected else UITokens.PAPER_300)
	_style()

func _style() -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = UITokens.INK_700 if (_hover or selected) else UITokens.INK_800
	sb.border_color = UITokens.SIGNAL_GOLD if (selected or _focused) else UITokens.INK_600
	sb.set_border_width_all(UITokens.BORDER_CONTROL if (selected or _focused) else UITokens.BORDER_PANEL)
	sb.set_corner_radius_all(UITokens.RADIUS_PANEL)
	sb.content_margin_left = 12.0
	sb.content_margin_right = 12.0
	sb.content_margin_top = 6.0
	sb.content_margin_bottom = 6.0
	add_theme_stylebox_override("panel", sb)
