extends ModalShell

# Echoes Beyond Earth — Field Manual (Phase 3)
# Replaces the old "Roblox style" controls text. Four pages: SCAN → DIG → CATALOGUE → CONTROLS.
# Key-caps are read from the InputMap, so hints follow any future rebinding.
# Shown automatically on first run (HUD) and on demand (pause menu / main menu).

signal manual_closed

const PAGES := [
	{
		"icon": "scan", "title": "Scan the surface",
		"body": "The proximity scanner runs on its own. It reports distance and signal strength, never what is buried. Walk toward a stronger signal.",
		"actions": [],
	},
	{
		"icon": "dig", "title": "Excavate",
		"body": "When the scanner reads an anomaly directly beneath you, begin excavation, then clean the find with the brush.",
		"actions": [["interact", "Begin excavation"], ["inspect_signal", "Inspect signal"]],
	},
	{
		"icon": "journal", "title": "Catalogue",
		"body": "Every recovered object is filed in the journal with its mission record. Complete the Moon to unlock Mars.",
		"actions": [["toggle_journal", "Open journal"]],
	},
	{
		"icon": "settings", "title": "Controls",
		"body": "",
		"actions": [
			["move_forward", "Forward"], ["move_backward", "Back"], ["move_left", "Left"], ["move_right", "Right"],
			["jump", "Jump"], ["gait_toggle", "Walk / bound"], ["view_toggle", "Camera view"],
			["inspect_geology", "Inspect geology"], ["toggle_journal", "Journal"],
		],
	},
]

var _page: int = 0
var _icon: TextureRect
var _step: Label
var _title: Label
var _text: Label
var _actions: VBoxContainer
var _dots: HBoxContainer
var _prev: Button
var _next: Button


func _init() -> void:
	title_text = "Field manual"
	card_width = 640
	layer_id = UITokens.LAYER_CINEMA + 5  # above HUD and cinema, below the pause/system layer


func _build_content() -> void:
	closed.connect(func() -> void: manual_closed.emit())

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", UITokens.SP_4)
	body.add_child(head)
	_icon = UITokens.make_icon("scan", UITokens.SIGNAL_GOLD, 40)
	head.add_child(_icon)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(col)
	_step = Label.new()
	_step.theme_type_variation = &"StatLabel"
	_step.add_theme_color_override("font_color", UITokens.PAPER_300)
	col.add_child(_step)
	_title = Label.new()
	_title.theme_type_variation = &"DisplayLabel"
	col.add_child(_title)

	_text = Label.new()
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(0, 64)
	_text.add_theme_color_override("font_color", UITokens.PAPER_300)
	body.add_child(_text)

	_actions = VBoxContainer.new()
	_actions.add_theme_constant_override("separation", UITokens.SP_2)
	_actions.custom_minimum_size = Vector2(0, 232)  # fixed so pages do not jump
	body.add_child(_actions)

	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", UITokens.SP_3)
	body.add_child(nav)
	_prev = Button.new()
	_prev.text = "Back"
	_prev.icon = UITokens.icon("chevron_left")
	_prev.theme_type_variation = &"GhostButton"
	_prev.pressed.connect(_go.bind(-1))
	nav.add_child(_prev)

	_dots = HBoxContainer.new()
	_dots.alignment = BoxContainer.ALIGNMENT_CENTER
	_dots.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_dots.add_theme_constant_override("separation", UITokens.SP_2)
	nav.add_child(_dots)
	for i in PAGES.size():
		var d := ColorRect.new()
		d.custom_minimum_size = Vector2(16, 4)
		_dots.add_child(d)

	_next = Button.new()
	_next.theme_type_variation = &"PrimaryButton"
	_next.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_next.pressed.connect(_go.bind(1))
	nav.add_child(_next)

	_refresh()


func _refresh() -> void:
	var p: Dictionary = PAGES[_page]
	_icon.texture = UITokens.icon(String(p["icon"]))
	_step.text = "STEP %02d / %02d" % [_page + 1, PAGES.size()]
	_title.text = String(p["title"]).to_upper()
	_text.text = String(p["body"])
	_text.visible = _text.text != ""

	for c in _actions.get_children():
		c.queue_free()
	var acts: Array = p["actions"]
	# Controls page: two columns so nine rows fit; other pages: one column.
	var two_col: bool = acts.size() > 4
	var grid := GridContainer.new()
	grid.columns = 2 if two_col else 1
	grid.add_theme_constant_override("h_separation", UITokens.SP_8)
	grid.add_theme_constant_override("v_separation", UITokens.SP_2)
	_actions.add_child(grid)
	for a in acts:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", UITokens.SP_3)
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var cap := KeyCap.new()
		cap.action_name = String(a[0])
		cap.custom_minimum_size = Vector2(44, 28)
		row.add_child(cap)
		var verb := Label.new()
		verb.text = String(a[1])
		row.add_child(verb)
		grid.add_child(row)
	if _page == PAGES.size() - 1:
		var look := Label.new()
		look.text = "Mouse: look around.  Esc: pause."
		look.theme_type_variation = &"CaptionLabel"
		_actions.add_child(look)

	for i in _dots.get_child_count():
		var d: ColorRect = _dots.get_child(i)
		d.color = UITokens.SIGNAL_GOLD if i == _page else UITokens.PAPER_500

	_prev.visible = _page > 0
	var last: bool = _page == PAGES.size() - 1
	_next.text = "Begin" if last else "Next"
	_next.icon = UITokens.icon("check") if last else UITokens.icon("chevron_right")


func _go(delta: int) -> void:
	var target: int = _page + delta
	if target >= PAGES.size():
		close()
		return
	_page = clampi(target, 0, PAGES.size() - 1)
	_refresh()
	_next.grab_focus()


# ── Public API (kept from the earlier scaffold) ──────────────────────────────────────

## Whether the first-run manual still has to be shown.
static func should_show() -> bool:
	return SettingsStore.first_run_pending()


func show_manual() -> void:
	_page = 0
	_refresh()
	open(_next)


func close() -> void:
	# Closing the manual by any route counts as having seen it.
	if visible:
		SettingsStore.mark_first_run_done()
	super.close()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	# Page turn on the standard UI actions (keyboard arrows and gamepad d-pad both map to these).
	if event.is_action_pressed("ui_right"):
		_go(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_left") and _page > 0:
		_go(-1)
		get_viewport().set_input_as_handled()
	else:
		super._unhandled_input(event)
