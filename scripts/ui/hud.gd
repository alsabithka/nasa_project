extends Control

# Echoes Beyond Earth - In-Game HUD, Mystery Scanner Radar, Discovery & Flashback Flow
# Phase 4: UITokens colours applied; Toast notifications on discovery
# Phase 6: the journal is the JournalDrawer component (archive drawer); old JournalModal nodes are gone.
# Phase 5: the discovery popup is gone — the Catalogue Entry (scientific_examination_panel.gd)
# replaces it. WATCH STORY arrives via play_artifact_story() (group "hud").

const UITokens = preload("res://scripts/ui/ui_tokens.gd")
const Toast    = preload("res://scripts/ui/components/toast.gd")

@export var current_planet: String = "Moon"

# UI Nodes
# Phase 4: the top bar and scanner now live in the WorldHud component (built in _ready).
var world_hud: WorldHud
var location_label: Label
var counter_label: Label
var journal_button: Button
var menu_button: Button
var radar_panel: Control   # the scanner instrument; hidden while a modal is open
var _signal_toasted: Dictionary = {}

# Journal (Phase 6): archive drawer built in code, owns tabs / filters / slots / detail.
var journal: JournalDrawer

# Mission Complete Banner
@onready var completion_modal: PanelContainer = $CompletionModal
@onready var completion_desc: Label = $CompletionModal/MarginContainer/VBoxContainer/DescLabel
@onready var travel_mars_btn: Button = $CompletionModal/MarginContainer/VBoxContainer/BtnContainer/TravelMarsBtn
@onready var continue_btn: Button = $CompletionModal/MarginContainer/VBoxContainer/BtnContainer/ContinueBtn

var selected_journal_planet: String = ""
var _last_discovered_id: String = ""

# Phase 3 — pause menu + field manual instances
var _pause_menu = null
var _field_manual = null

func _ready() -> void:
	add_to_group("hud")
	_build_world_hud()
	_update_header()
	_connect_gamestate()
	_connect_scanner()
	_build_journal()
	_setup_buttons()
	_setup_pause_menu()
	_check_field_manual()
	
	completion_modal.visible = false
	selected_journal_planet = current_planet

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_journal"):
		toggle_journal()
	elif event.is_action_pressed("ui_cancel"):
		# ESC priority: the journal consumes Esc itself (JournalDrawer._input); this branch is a
		# fallback. Then open modals, then the pause menu.
		if journal.is_open():
			journal.close()
			get_viewport().set_input_as_handled()
		elif completion_modal.visible:
			pass  # don't dismiss mission complete
		else:
			_open_pause()
			get_viewport().set_input_as_handled()

func _setup_buttons() -> void:
	journal_button.pressed.connect(toggle_journal)
	menu_button.pressed.connect(_on_menu_pressed)
	if continue_btn:
		continue_btn.pressed.connect(func(): completion_modal.visible = false)
	if travel_mars_btn:
		travel_mars_btn.pressed.connect(_travel_to_mars)

func _build_journal() -> void:
	journal = JournalDrawer.new()
	add_child(journal)
	journal.closed.connect(_on_journal_closed)
	journal.story_requested.connect(play_artifact_story)

## Every way of closing the journal (Close, Esc, J, WATCH STORY) ends here.
func _on_journal_closed() -> void:
	radar_panel.visible = true
	if not completion_modal.visible and not (_pause_menu != null and _pause_menu.is_open()):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_world_hud() -> void:
	world_hud = WorldHud.new()
	add_child(world_hud)
	move_child(world_hud, 0)  # behind the modals defined in the scene
	location_label = world_hud.location_label
	counter_label = world_hud.counter_label
	journal_button = world_hud.journal_button
	menu_button = world_hud.menu_button
	radar_panel = world_hud.scanner


func _connect_gamestate() -> void:
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return
	
	gs.artifact_recovered.connect(_on_artifact_recovered)
	gs.mission_completed.connect(_on_mission_completed)
	gs.planet_unlocked.connect(func(planet: String) -> void:
		Toast.notify(get_tree(), "%s UNLOCKED" % planet.to_upper(), UITokens.SIGNAL_GREEN))
	_update_header()

func _connect_scanner() -> void:
	var scanners = get_tree().get_nodes_in_group("scanner")
	for s in scanners:
		if s.has_signal("scan_updated"):
			s.scan_updated.connect(_on_scan_updated)

# Mystery Scanner: proximity and signal strength only, NEVER reveals artifact identity.
func _on_scan_updated(target_id: String, distance: float, signal_strength: float) -> void:
	world_hud.scanner.update_reading(target_id, distance, signal_strength)
	# One "signal acquired" toast per target, the first time it comes into range.
	if target_id != "" and distance <= world_hud.scanner.MAX_RANGE and not _signal_toasted.has(target_id):
		_signal_toasted[target_id] = true
		Toast.notify(get_tree(), "SIGNAL ACQUIRED", UITokens.SIGNAL_CYAN)

func _on_artifact_recovered(artifact_id: String) -> void:
	_last_discovered_id = artifact_id
	_update_header()
	if journal.is_open():
		journal.refresh()
	# Phase 5: the Catalogue Entry already showed the full record; this confirms the journal store.
	var gs = get_node_or_null("/root/GameState")
	var art_name := artifact_id.capitalize()
	if gs:
		var d = gs.get_artifact_data(artifact_id)
		if d and d.has("name"):
			art_name = d["name"]
	Toast.notify(get_tree(), "SPECIMEN STORED — %s" % art_name, UITokens.SIGNAL_GOLD)

## Public hand-over used by artifact.gd when the player chooses WATCH STORY in the Catalogue Entry.
func play_artifact_story(artifact_id: String) -> void:
	_last_discovered_id = artifact_id
	_trigger_flashback(artifact_id)

## Kept for compatibility (test_artifact_video_system): "the discovery acknowledgement closed,
## start the story for the last discovered artifact".
func _on_popup_closed() -> void:
	radar_panel.visible = true
	if _last_discovered_id != "":
		_trigger_flashback(_last_discovered_id)

# Starts the artifact documentary. The player scene plays the artifact's video when
# data/artifact_videos.json has a playable entry, and otherwise runs the original text
# flashback (data/flashbacks.json) itself, so every artifact still gets a story.
func _trigger_flashback(artifact_id: String) -> void:
	var player_scene = load("res://scenes/ui/artifact_video_player.tscn")
	if player_scene:
		var story = player_scene.instantiate()
		story.artifact_id = artifact_id
		story.playback_complete.connect(_on_artifact_story_complete)
		add_child(story)
	else:
		# Safety net: the player scene is missing, use the original text flashback directly
		var flashback_scene = load("res://scenes/ui/flashback.tscn")
		if flashback_scene:
			var fb = flashback_scene.instantiate()
			fb.artifact_id = artifact_id
			if fb.has_signal("flashback_complete"):
				fb.flashback_complete.connect(_on_flashback_complete)
			add_child(fb)

func _on_artifact_story_complete(_artifact_id: String, _result: String) -> void:
	_on_flashback_complete()

func _on_flashback_complete() -> void:
	if not journal.is_open() and not completion_modal.visible:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("capture_mouse"):
			player.capture_mouse()

func _on_mission_completed(planet: String) -> void:
	if completion_modal:
		completion_modal.visible = true
		# artifact.gd recaptures the mouse right after identifying; show it again once that has run
		# so the buttons of this modal can be clicked.
		call_deferred("_show_mouse")
		if planet == "Moon":
			completion_desc.text = "You have excavated, restored, and cataloged all historical Apollo lunar equipment! Mars exploration coordinates are now unlocked."
			if travel_mars_btn:
				travel_mars_btn.visible = true
		else:
			completion_desc.text = "Congratulations! You have successfully surveyed all historical Martian exploration artifacts!"
			if travel_mars_btn:
				travel_mars_btn.visible = false

func _show_mouse() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _travel_to_mars() -> void:
	completion_modal.visible = false
	get_tree().change_scene_to_file("res://scenes/levels/mars.tscn")

func _update_header() -> void:
	var gs = get_node_or_null("/root/GameState")
	if gs:
		var rec = gs.get_recovered_count(current_planet)
		var total = gs.get_total_count(current_planet)
		world_hud.set_progress(current_planet, rec, total)
	else:
		world_hud.set_progress(current_planet, 0, 0)

func toggle_journal() -> void:
	if journal.is_open():
		journal.close()      # _on_journal_closed restores scanner + mouse
		return
	# B7: the scanner widget is hidden while the journal is open (and the drawer dims the world).
	radar_panel.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	journal.open(selected_journal_planet if selected_journal_planet != "" else current_planet)

## Kept for compatibility: switches the open journal to `planet`.
func _populate_journal(planet: String) -> void:
	selected_journal_planet = planet
	journal.show_planet(planet)

func _on_menu_pressed() -> void:
	_open_pause()

# ─── Pause Menu helpers ──────────────────────────────────────────────────────

func _setup_pause_menu() -> void:
	var pm_scene = load("res://scenes/ui/pause_menu.tscn")
	if pm_scene:
		_pause_menu = pm_scene.instantiate()
		add_child(_pause_menu)
		_pause_menu.resume_requested.connect(_close_pause)
		_pause_menu.open_journal_requested.connect(func():
			_close_pause()
			toggle_journal()
		)


func _open_pause() -> void:
	if _pause_menu:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_pause_menu.show_pause()


func _close_pause() -> void:
	if _pause_menu:
		_pause_menu.hide_pause()
		if not journal.is_open() and not completion_modal.visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


# ─── Field Manual ────────────────────────────────────────────────────────────

func _check_field_manual() -> void:
	# Load field_manual.gd static method via ResourceLoader (safe — no Autoload)
	var fm_script = load("res://scripts/ui/field_manual.gd")
	if fm_script and fm_script.should_show():
		var fm_scene = load("res://scenes/ui/field_manual.tscn")
		if fm_scene:
			_field_manual = fm_scene.instantiate()
			add_child(_field_manual)
			_field_manual.manual_closed.connect(func():
				if _field_manual:
					Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			)
			# Slight delay so the HUD fully initialises before showing manual
			await get_tree().create_timer(0.3).timeout
			if is_inside_tree() and _field_manual:
				_field_manual.show_manual()
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

# B3 HELPER: format year values cleanly regardless of float/int/string type
func _format_year(val) -> String:
	if val is float or val is int:
		return str(int(val))
	return str(val)

# Phase 8: Tween-based modal open — scale + fade in using UITokens duration
func _animate_modal_open(node: Control) -> void:
	node.modulate.a = 0.0
	node.scale = Vector2(0.96, 0.96)
	node.pivot_offset = node.size * 0.5
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(node, "modulate:a", 1.0, UITokens.DURATION_BASE)
	tw.tween_property(node, "scale", Vector2.ONE, UITokens.DURATION_BASE).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
