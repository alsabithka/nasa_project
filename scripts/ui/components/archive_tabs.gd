class_name ArchiveTabs
extends HBoxContainer

## Echoes Beyond Earth — ArchiveTabs Component
## Row of toggle TabButtons with an unmistakable selected state (gold underline + gold text —
## a shape change, not only a colour change). Replaces `modulate` tinting of journal tabs (B6).
## Usage:
##   var tabs := ArchiveTabs.new(); tabs.set_tabs(["Moon", "Mars"]); tabs.tab_selected.connect(_on_tab)
##   tabs.select(0)

signal tab_selected(index: int)

var selected: int = -1
var _buttons: Array[Button] = []
var _group := ButtonGroup.new()

func _ready() -> void:
	add_theme_constant_override("separation", 0)

func set_tabs(labels: Array) -> void:
	for b in _buttons:
		b.queue_free()
	_buttons.clear()
	for i in labels.size():
		var b := Button.new()
		b.text = str(labels[i])
		b.theme_type_variation = &"TabButton"
		b.toggle_mode = true
		b.button_group = _group
		b.focus_mode = Control.FOCUS_ALL
		b.pressed.connect(_on_pressed.bind(i))
		add_child(b)
		_buttons.append(b)

func select(index: int, emit: bool = true) -> void:
	if index < 0 or index >= _buttons.size():
		return
	selected = index
	_buttons[index].set_pressed_no_signal(true)
	if emit:
		tab_selected.emit(index)

func set_tab_disabled(index: int, off: bool) -> void:
	if index >= 0 and index < _buttons.size():
		_buttons[index].disabled = off

func get_button(index: int) -> Button:
	return _buttons[index] if index >= 0 and index < _buttons.size() else null

func _on_pressed(index: int) -> void:
	selected = index
	tab_selected.emit(index)
