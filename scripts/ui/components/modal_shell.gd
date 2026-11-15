class_name ModalShell
extends CanvasLayer

## Echoes Beyond Earth — ModalShell (Phase 3)
## Shared frame for system modals (settings, field manual, credits): dimmed overlay, themed
## ArchiveCard, title row with a Close button + Esc key-cap, `body` VBox for content.
##
## Subclass or configure before add_child():
##   var m := ModalShell.new(); m.title_text = "CREDITS"; m.card_width = 560
##   m.body.add_child(...)  (body exists after the node enters the tree; use _build_content() in a subclass)
##   m.open(some_focus_control)
##
## Behaviour: runs while the tree is paused, Esc / ui_cancel closes it (and is consumed so lower
## layers never see it), initial focus is explicit, and focus returns to whatever had it before.

signal closed

var title_text: String = ""
var card_width: int = 560
var layer_id: int = UITokens.LAYER_SYSTEM
var close_on_cancel: bool = true

var body: VBoxContainer
var card: PanelContainer
var close_button: Button

var _root: Control
var _dim: ColorRect
var _return_focus: Control = null
var _preferred_focus: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = layer_id
	add_to_group("blocking_modal")  # HUD journal / pause hotkeys are inert while visible (merge §9.2)
	_build_shell()
	_build_content()
	visible = false


## Override in subclasses; add controls to `body`.
func _build_content() -> void:
	pass


func _build_shell() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITokens.theme()
	add_child(_root)

	_dim = ColorRect.new()
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.color = Color(UITokens.INK_900, 0.82)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP  # swallow clicks behind the modal
	_root.add_child(_dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	card = PanelContainer.new()
	card.theme_type_variation = &"ArchiveCard"
	card.custom_minimum_size = Vector2(card_width, 0)
	center.add_child(card)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UITokens.SP_4)
	card.add_child(col)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UITokens.SP_3)
	col.add_child(head)

	var t := Label.new()
	t.text = title_text.to_upper()
	t.theme_type_variation = &"TitleLabel"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(t)

	close_button = Button.new()
	close_button.text = "Close"
	close_button.icon = UITokens.icon("close")
	close_button.theme_type_variation = &"GhostButton"
	close_button.pressed.connect(close)
	head.add_child(close_button)

	var cap := KeyCap.new()
	cap.label_override = "Esc"
	head.add_child(cap)

	var rule := ColorRect.new()
	rule.color = UITokens.PAPER_500
	rule.custom_minimum_size = Vector2(0, 1)
	col.add_child(rule)

	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", UITokens.SP_3)
	col.add_child(body)


## Show the modal. `focus_target` gets focus (falls back to the Close button).
func open(focus_target: Control = null) -> void:
	if _root == null:
		push_warning("ModalShell.open() called before the node entered the tree")
		return
	_return_focus = get_viewport().gui_get_focus_owner()
	_preferred_focus = focus_target
	visible = true
	var d: float = UITokens.DURATION_FAST * SettingsStore.motion_scale()
	if d > 0.0:
		card.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(card, "modulate:a", 1.0, d)
	else:
		card.modulate.a = 1.0
	_focus_deferred.call_deferred()


func _focus_deferred() -> void:
	var target: Control = close_button
	if _preferred_focus != null and is_instance_valid(_preferred_focus) and _preferred_focus.focus_mode != Control.FOCUS_NONE:
		target = _preferred_focus
	if target != null and target.is_inside_tree():
		target.grab_focus()


func close() -> void:
	if not visible:
		return
	visible = false
	if _return_focus != null and is_instance_valid(_return_focus) and _return_focus.is_inside_tree() and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus()
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and close_on_cancel and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


# ── Shared control builders (token-styled, usable by any code-built panel) ───────────────

static func _flat(bg: Color, border: Color, bw: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(bw)
	sb.set_corner_radius_all(0)
	return sb


static func _square_icon(w: int, h: int, c: Color) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(c)
	return ImageTexture.create_from_image(img)


## Brutalist slider: thin rail, gold fill, square gold handle, gold focus ring.
static func style_slider(s: HSlider) -> void:
	var rail := _flat(UITokens.INK_700, UITokens.PAPER_500, 1)
	rail.content_margin_top = 3.0
	rail.content_margin_bottom = 3.0
	s.add_theme_stylebox_override("slider", rail)
	var fill := _flat(UITokens.SIGNAL_GOLD, UITokens.SIGNAL_GOLD, 0)
	fill.content_margin_top = 3.0
	fill.content_margin_bottom = 3.0
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	var handle: ImageTexture = _square_icon(10, 22, UITokens.SIGNAL_GOLD)
	var handle_hi: ImageTexture = _square_icon(10, 22, UITokens.PAPER_100)
	s.add_theme_icon_override("grabber", handle)
	s.add_theme_icon_override("grabber_highlight", handle_hi)
	s.add_theme_icon_override("grabber_disabled", _square_icon(10, 22, UITokens.PAPER_500))
	var ring := StyleBoxFlat.new()
	ring.draw_center = false
	ring.border_color = UITokens.SIGNAL_GOLD
	ring.set_border_width_all(2)
	s.add_theme_stylebox_override("focus", ring)
	s.custom_minimum_size = Vector2(200, 28)
	s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
