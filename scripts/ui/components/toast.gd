class_name Toast
extends CanvasLayer

## Echoes Beyond Earth — Toast Component
## A self-dismissing notification banner. Slides in from top, holds, then
## fades out automatically. Respects UITokens motion durations.
##
## Usage (call from any node):
##   var t := preload("res://scenes/ui/components/toast.tscn").instantiate()
##   get_tree().root.add_child(t)
##   t.show_toast("Signal acquired", UITokens.SIGNAL_CYAN)
##
## Or use the static helper (adds to scene root automatically):
##   Toast.notify(get_tree(), "Specimen stored", UITokens.SIGNAL_GREEN)

signal toast_dismissed

@export var hold_duration: float = 2.8

var _panel: PanelContainer
var _label: Label
var _tween: Tween

func _ready() -> void:
	layer = UITokens.LAYER_SYSTEM  # above modals, below debug
	_build_ui()

func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_panel.offset_left   = 160
	_panel.offset_right  = -160
	_panel.offset_top    = -60     # start off-screen
	_panel.offset_bottom = -4

	var sb := StyleBoxFlat.new()
	sb.bg_color     = UITokens.INK_700
	sb.border_color = UITokens.SIGNAL_CYAN
	sb.set_border_width_all(UITokens.BORDER_CONTROL)
	sb.set_corner_radius_all(UITokens.RADIUS_CONTROL)
	sb.content_margin_left   = float(UITokens.SP_4)
	sb.content_margin_top    = float(UITokens.SP_2)
	sb.content_margin_right  = float(UITokens.SP_4)
	sb.content_margin_bottom = float(UITokens.SP_2)
	_panel.add_theme_stylebox_override("panel", sb)

	var root_ctrl := Control.new()
	root_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_ctrl)
	root_ctrl.add_child(_panel)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
	_label.add_theme_color_override("font_color", UITokens.PAPER_100)
	_panel.add_child(_label)

## Display the toast. accent_color tints the border.
func show_toast(message: String, accent_color: Color = UITokens.SIGNAL_CYAN) -> void:
	_label.text = message

	# Update border colour for context (cyan=info, green=success, gold=warning, red=error)
	var sb := _panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	sb.border_color = accent_color
	_panel.add_theme_stylebox_override("panel", sb)

	if _tween:
		_tween.kill()

	_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	# Slide in
	_tween.tween_property(_panel, "offset_top",    8.0, UITokens.DURATION_BASE)
	_tween.tween_property(_panel, "offset_bottom", 52.0, UITokens.DURATION_BASE)
	# Hold
	_tween.tween_interval(hold_duration)
	# Fade out
	_tween.tween_property(_panel, "modulate:a", 0.0, UITokens.DURATION_FAST)
	_tween.tween_callback(_dismiss)

func _dismiss() -> void:
	toast_dismissed.emit()
	queue_free()

## Static convenience method — creates and shows a toast on the scene root.
static func notify(tree: SceneTree, message: String, accent: Color = Color(0.502, 0.8, 1.0)) -> void:
	var scene := load("res://scenes/ui/components/toast.tscn")
	if not scene:
		push_warning("Toast: scene not found at res://scenes/ui/components/toast.tscn")
		return
	var t: Toast = scene.instantiate()
	tree.root.add_child(t)
	t.show_toast(message, accent)
