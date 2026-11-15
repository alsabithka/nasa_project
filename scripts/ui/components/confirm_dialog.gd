class_name ConfirmDialog
extends CanvasLayer

## Echoes Beyond Earth — ConfirmDialog Component
## Modal yes/no. Cancel is focused first (safe default) and Esc cancels.
## Runs while the tree is paused. Frees itself after answering.
##   var d := ConfirmDialog.ask(get_tree(), "Quit to menu?", "Unsaved progress will be lost.", "Quit")
##   d.confirmed.connect(_do_quit)

signal confirmed
signal cancelled

var title_text := "Are you sure?"
var message_text := ""
var confirm_text := "Confirm"
var cancel_text := "Cancel"
var danger := false

var _cancel_btn: Button
var _answered := false

static func ask(tree: SceneTree, title: String, message: String, confirm_label: String = "Confirm", is_danger: bool = false) -> ConfirmDialog:
	var d := ConfirmDialog.new()
	d.title_text = title
	d.message_text = message
	d.confirm_text = confirm_label
	d.danger = is_danger
	tree.root.add_child(d)
	return d

func _ready() -> void:
	layer = UITokens.LAYER_SYSTEM + 2  # above pause (40) and its child modals (41)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UITokens.theme()
	add_child(root)
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(UITokens.INK_900.r, UITokens.INK_900.g, UITokens.INK_900.b, 0.78)
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(center)
	var card := PanelContainer.new()
	card.theme_type_variation = &"ArchiveCard"
	card.custom_minimum_size.x = 440
	center.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UITokens.SP_4)
	card.add_child(col)
	var t := Label.new()
	t.theme_type_variation = &"TitleLabel"
	t.text = title_text
	col.add_child(t)
	var m := Label.new()
	m.text = message_text
	m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	m.add_theme_color_override("font_color", UITokens.PAPER_300)
	col.add_child(m)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END
	row.add_theme_constant_override("separation", UITokens.SP_3)
	col.add_child(row)
	_cancel_btn = Button.new()
	_cancel_btn.text = cancel_text
	_cancel_btn.theme_type_variation = &"GhostButton"
	_cancel_btn.pressed.connect(_answer.bind(false))
	row.add_child(_cancel_btn)
	var ok := Button.new()
	ok.text = confirm_text
	ok.theme_type_variation = &"PrimaryButton"
	ok.pressed.connect(_answer.bind(true))
	if danger:
		ok.add_theme_color_override("font_color", UITokens.INK_900)
		var sb := StyleBoxFlat.new()
		sb.bg_color = UITokens.SIGNAL_RED
		sb.set_corner_radius_all(UITokens.RADIUS_CONTROL)
		sb.content_margin_left = 12.0; sb.content_margin_right = 12.0
		sb.content_margin_top = 8.0; sb.content_margin_bottom = 8.0
		ok.add_theme_stylebox_override("normal", sb)
	row.add_child(ok)
	_cancel_btn.call_deferred("grab_focus")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_answer(false)
		get_viewport().set_input_as_handled()

func _answer(yes: bool) -> void:
	if _answered:
		return
	_answered = true
	if yes:
		confirmed.emit()
	else:
		cancelled.emit()
	queue_free()
