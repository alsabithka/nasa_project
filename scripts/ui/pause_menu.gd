extends CanvasLayer

# Echoes Beyond Earth — Pause Menu (Phase 3)
# Left-aligned archive panel over a dimmed world. One Esc policy for the whole game:
#   close the top modal first, otherwise open pause; Esc inside pause resumes.
# Runs while the tree is paused. Key hints come from the InputMap via KeyCap.
# Signals kept for the HUD: resume_requested, open_journal_requested.
# (Settings, controls and quit are handled here, so open_settings_requested is no longer emitted.)

signal resume_requested
signal open_journal_requested
signal open_settings_requested  # deprecated: kept so older connections do not break

var _root: Control
var _panel: PanelContainer
var _is_open: bool = false
var _child_modal_open: bool = false
var _resume_btn: Button
var _settings: Node = null
var _manual: Node = null
var _progress_label: Label
var _progress_meter: SegmentedMeter
var _last_focus: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = UITokens.LAYER_SYSTEM
	_build_ui()
	_set_visible_state(false)


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.theme = UITokens.theme()
	add_child(_root)

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(UITokens.INK_900, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)

	# Full-height panel on the left edge, 4-column Swiss feel: 400 px wide at the 1280 base.
	_panel = PanelContainer.new()
	_panel.theme_type_variation = &"ArchiveCard"
	_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	_panel.offset_left = 0.0
	_panel.offset_right = 400.0
	_root.add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", UITokens.SP_8)
	margin.add_theme_constant_override("margin_right", UITokens.SP_8)
	margin.add_theme_constant_override("margin_top", UITokens.SP_8)
	margin.add_theme_constant_override("margin_bottom", UITokens.SP_8)
	_panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", UITokens.SP_2)
	margin.add_child(col)

	var title := Label.new()
	title.text = "PAUSED"
	title.theme_type_variation = &"DisplayLabel"
	col.add_child(title)

	_progress_label = Label.new()
	_progress_label.theme_type_variation = &"StatLabel"
	_progress_label.add_theme_color_override("font_color", UITokens.PAPER_300)
	col.add_child(_progress_label)
	_progress_meter = SegmentedMeter.new()
	_progress_meter.accent = UITokens.SIGNAL_GOLD
	_progress_meter.custom_minimum_size = Vector2(0, 10)
	col.add_child(_progress_meter)

	col.add_child(_spacer(UITokens.SP_6))

	_resume_btn = _add_item(col, "Resume", "play", "", "Esc", _on_resume)
	_add_item(col, "Journal", "journal", "toggle_journal", "", _on_journal)
	_add_item(col, "Settings", "settings", "", "", _on_settings)
	_add_item(col, "Field manual", "scan", "", "", _on_controls)

	var grow := Control.new()
	grow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(grow)

	_add_item(col, "Quit to menu", "close", "", "", _on_quit)


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


## One menu row: ghost button with icon + label, key-cap hint docked right.
func _add_item(parent: Control, text: String, icon_name: String, action: String, cap_text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.icon = UITokens.icon(icon_name)
	b.theme_type_variation = &"GhostButton"
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 44)
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(cb)
	parent.add_child(b)
	if action != "" or cap_text != "":
		var cap := KeyCap.new()
		if action != "":
			cap.action_name = action
		else:
			cap.label_override = cap_text
		cap.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		cap.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		cap.grow_vertical = Control.GROW_DIRECTION_BOTH
		cap.offset_right = -float(UITokens.SP_3)
		cap.offset_left = -float(UITokens.SP_3)
		b.add_child(cap)
	return b


# ── Public API ───────────────────────────────────────────────────────────────────────

func is_open() -> bool:
	return _is_open


func show_pause() -> void:
	if _is_open:
		return
	_refresh_progress()
	_set_visible_state(true)
	get_tree().paused = true
	_resume_btn.grab_focus.call_deferred()


func hide_pause() -> void:
	if not _is_open:
		return
	_set_visible_state(false)
	get_tree().paused = false


func _set_visible_state(open: bool) -> void:
	_is_open = open
	if _root != null:
		_root.visible = open


func _refresh_progress() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	var planet: String = "Moon"
	var found: int = 0
	var total: int = 0
	if gs != null:
		planet = String(gs.get("current_planet"))
		found = int(gs.call("get_recovered_count", planet))
		total = int(gs.call("get_total_count", planet))
	_progress_label.text = "%s  %d / %d catalogued" % [planet.to_upper(), found, total]
	_progress_meter.segment_count = maxi(1, total)
	_progress_meter.value = float(found) / float(maxi(1, total))


# ── Actions ──────────────────────────────────────────────────────────────────────────

func _on_resume() -> void:
	hide_pause()
	resume_requested.emit()


func _on_journal() -> void:
	hide_pause()
	open_journal_requested.emit()


func _on_settings() -> void:
	if _settings == null or not is_instance_valid(_settings):
		var scene: PackedScene = load("res://scenes/ui/settings_menu.tscn") as PackedScene
		if scene == null:
			return
		_settings = scene.instantiate()
		add_child(_settings)
		_settings.settings_closed.connect(_on_child_closed)
	_begin_child_modal()
	_settings.show_settings()


func _on_controls() -> void:
	if _manual == null or not is_instance_valid(_manual):
		var scene: PackedScene = load("res://scenes/ui/field_manual.tscn") as PackedScene
		if scene == null:
			return
		_manual = scene.instantiate()
		add_child(_manual)
		_manual.manual_closed.connect(_on_child_closed)
	_begin_child_modal()
	_manual.show_manual()


func _begin_child_modal() -> void:
	_child_modal_open = true


func _on_child_closed() -> void:
	# Defer one frame so the Esc that closed the child is not read again by this menu.
	_clear_child_flag.call_deferred()


func _clear_child_flag() -> void:
	_child_modal_open = false


func _on_quit() -> void:
	_child_modal_open = true
	var d: ConfirmDialog = ConfirmDialog.ask(get_tree(), "Quit to menu?",
		"Progress in this session is not saved.", "Quit to menu", true)
	d.confirmed.connect(func() -> void:
		SceneFade.go(get_tree(), "res://scenes/main_menu.tscn"))
	d.cancelled.connect(_on_child_closed)
	d.confirmed.connect(_on_child_closed)


func _unhandled_input(event: InputEvent) -> void:
	if not _is_open or _child_modal_open:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_resume()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_journal"):
		_on_journal()
		get_viewport().set_input_as_handled()
