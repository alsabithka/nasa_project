extends Control

# Echoes Beyond Earth - In-Game HUD, Mystery Scanner Radar, Discovery & Flashback Flow
# Phase 4: UITokens colours applied; Toast notifications on discovery

const UITokens = preload("res://scripts/ui/ui_tokens.gd")
const Toast    = preload("res://scripts/ui/components/toast.gd")

@export var current_planet: String = "Moon"

# UI Nodes
@onready var location_label: Label = $TopBar/MarginContainer/HBoxContainer/LocationLabel
@onready var counter_label: Label = $TopBar/MarginContainer/HBoxContainer/CounterBadge/CounterLabel
@onready var journal_button: Button = $TopBar/MarginContainer/HBoxContainer/JournalButton
@onready var menu_button: Button = $TopBar/MarginContainer/HBoxContainer/MenuButton

# Radar Widget
@onready var radar_panel: PanelContainer = $RadarWidget
@onready var distance_label: Label = $RadarWidget/VBoxContainer/DistanceLabel
@onready var strength_bar: ProgressBar = $RadarWidget/VBoxContainer/StrengthBar
@onready var target_name_label: Label = $RadarWidget/VBoxContainer/TargetNameLabel
@onready var compass_needle: Control = $RadarWidget/VBoxContainer/RadarCircle/Needle

# Discovery Popup
@onready var discovery_popup: PanelContainer = $DiscoveryPopup
@onready var popup_title: Label = $DiscoveryPopup/MarginContainer/VBoxContainer/TitleLabel
@onready var popup_name: Label = $DiscoveryPopup/MarginContainer/VBoxContainer/ArtifactNameLabel
@onready var popup_mission: Label = $DiscoveryPopup/MarginContainer/VBoxContainer/MissionLabel
@onready var popup_history: RichTextLabel = $DiscoveryPopup/MarginContainer/VBoxContainer/HistoryLabel
@onready var popup_close_btn: Button = $DiscoveryPopup/MarginContainer/VBoxContainer/ButtonContainer/CloseButton
@onready var popup_journal_btn: Button = $DiscoveryPopup/MarginContainer/VBoxContainer/ButtonContainer/OpenJournalButton

# Journal Modal
@onready var journal_modal: PanelContainer = $JournalModal
@onready var journal_list: VBoxContainer = $JournalModal/MarginContainer/VBoxContainer/ContentHBox/ScrollContainer/ArtifactList
@onready var journal_detail_name: Label = $JournalModal/MarginContainer/VBoxContainer/ContentHBox/DetailPanel/VBoxContainer/DetailName
@onready var journal_detail_text: RichTextLabel = $JournalModal/MarginContainer/VBoxContainer/ContentHBox/DetailPanel/VBoxContainer/DetailText
@onready var journal_close_btn: Button = $JournalModal/MarginContainer/VBoxContainer/HeaderHBox/CloseJournalBtn
@onready var moon_tab_btn: Button = $JournalModal/MarginContainer/VBoxContainer/TabHBox/MoonTabBtn
@onready var mars_tab_btn: Button = $JournalModal/MarginContainer/VBoxContainer/TabHBox/MarsTabBtn

# Mission Complete Banner
@onready var completion_modal: PanelContainer = $CompletionModal
@onready var completion_desc: Label = $CompletionModal/MarginContainer/VBoxContainer/DescLabel
@onready var travel_mars_btn: Button = $CompletionModal/MarginContainer/VBoxContainer/BtnContainer/TravelMarsBtn
@onready var continue_btn: Button = $CompletionModal/MarginContainer/VBoxContainer/BtnContainer/ContinueBtn

var selected_journal_planet: String = "Moon"
var _last_discovered_id: String = ""

# Phase 3 — pause menu + field manual instances
var _pause_menu = null
var _field_manual = null

func _ready() -> void:
	_update_header()
	_connect_gamestate()
	_connect_scanner()
	_setup_buttons()
	_setup_pause_menu()
	_check_field_manual()
	
	discovery_popup.visible = false
	journal_modal.visible = false
	completion_modal.visible = false
	# B6 FIX: set initial tab highlight state
	moon_tab_btn.modulate = Color(1.0, 0.85, 0.2)
	mars_tab_btn.modulate = Color(0.7, 0.75, 0.9)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_journal"):
		toggle_journal()
	elif event.is_action_pressed("ui_cancel"):
		# ESC priority: close open modals first, then open pause menu
		if discovery_popup.visible:
			_on_popup_closed()
			get_viewport().set_input_as_handled()
		elif journal_modal.visible:
			journal_modal.visible = false
			radar_panel.visible = true
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			get_viewport().set_input_as_handled()
		elif completion_modal.visible:
			pass  # don't dismiss mission complete
		else:
			_open_pause()
			get_viewport().set_input_as_handled()

func _setup_buttons() -> void:
	journal_button.pressed.connect(toggle_journal)
	menu_button.pressed.connect(_on_menu_pressed)
	popup_close_btn.pressed.connect(_on_popup_closed)
	popup_journal_btn.pressed.connect(_open_journal_to_last_discovered)
	journal_close_btn.pressed.connect(func(): journal_modal.visible = false)
	
	moon_tab_btn.pressed.connect(func(): _populate_journal("Moon"))
	mars_tab_btn.pressed.connect(func(): _populate_journal("Mars"))
	
	if continue_btn:
		continue_btn.pressed.connect(func(): completion_modal.visible = false)
	if travel_mars_btn:
		travel_mars_btn.pressed.connect(_travel_to_mars)

func _connect_gamestate() -> void:
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return
	
	gs.artifact_recovered.connect(_on_artifact_recovered)
	gs.mission_completed.connect(_on_mission_completed)
	_update_header()

func _connect_scanner() -> void:
	var scanners = get_tree().get_nodes_in_group("scanner")
	for s in scanners:
		if s.has_signal("scan_updated"):
			s.scan_updated.connect(_on_scan_updated)

# Mystery Scanner: Proximity and Signal Strength only, NEVER reveals artifact identity!
func _on_scan_updated(target_id: String, distance: float, signal_strength: float) -> void:
	if target_id == "" or distance > 60.0:
		distance_label.text = "-- m"
		strength_bar.value = 0
		target_name_label.text = "Searching for signals..."
		target_name_label.add_theme_color_override("font_color", UITokens.PAPER_500)
		distance_label.add_theme_color_override("font_color", UITokens.PAPER_500)
		if compass_needle:
			compass_needle.rotation = 0.0
		return
	
	distance_label.text = "%.1f m" % distance
	strength_bar.value = signal_strength * 100.0
	
	# Mystery-based signal categorization — Phase 4: use token colours
	if distance <= 4.0:
		target_name_label.text = "● ANOMALY BENEATH SURFACE — DIG HERE"
		target_name_label.add_theme_color_override("font_color", UITokens.SIGNAL_GREEN)
		distance_label.add_theme_color_override("font_color", UITokens.SIGNAL_GREEN)
	elif distance < 12.0:
		target_name_label.text = "▲ STRONG SUBSURFACE ANOMALY"
		target_name_label.add_theme_color_override("font_color", UITokens.SIGNAL_CYAN)
		distance_label.add_theme_color_override("font_color", UITokens.SIGNAL_CYAN)
	elif distance < 25.0:
		target_name_label.text = "◆ MODERATE SIGNAL DETECTED"
		target_name_label.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD)
		distance_label.add_theme_color_override("font_color", UITokens.SIGNAL_GOLD)
	else:
		target_name_label.text = "~ FAINT SIGNAL DETECTED"
		target_name_label.add_theme_color_override("font_color", UITokens.PAPER_300)
		distance_label.add_theme_color_override("font_color", UITokens.PAPER_300)

func _on_artifact_recovered(artifact_id: String) -> void:
	_last_discovered_id = artifact_id
	_update_header()
	_show_discovery_popup(artifact_id)
	if journal_modal.visible:
		_populate_journal(selected_journal_planet)
	# Phase 4: Toast notification on discovery
	var gs = get_node_or_null("/root/GameState")
	var art_name := artifact_id.capitalize()
	if gs:
		var d = gs.get_artifact_data(artifact_id)
		if d and d.has("name"):
			art_name = d["name"]
	Toast.notify(get_tree(), "ARTEFACT CATALOGUED — %s" % art_name, UITokens.SIGNAL_GOLD)

func _on_popup_closed() -> void:
	discovery_popup.visible = false
	# B7 FIX: restore scanner visibility when popup closes
	radar_panel.visible = true
	# Trigger the cinematic artifact story after discovery
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
	if not journal_modal.visible and not discovery_popup.visible and not completion_modal.visible:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("capture_mouse"):
			player.capture_mouse()

func _on_mission_completed(planet: String) -> void:
	if completion_modal:
		completion_modal.visible = true
		if planet == "Moon":
			completion_desc.text = "You have excavated, restored, and cataloged all historical Apollo lunar equipment! Mars exploration coordinates are now unlocked."
			if travel_mars_btn:
				travel_mars_btn.visible = true
		else:
			completion_desc.text = "Congratulations! You have successfully surveyed all historical Martian exploration artifacts!"
			if travel_mars_btn:
				travel_mars_btn.visible = false

func _travel_to_mars() -> void:
	completion_modal.visible = false
	get_tree().change_scene_to_file("res://scenes/levels/mars.tscn")

func _update_header() -> void:
	location_label.text = current_planet.to_upper() + " EXPLORATION"
	var gs = get_node_or_null("/root/GameState")
	if gs:
		var rec = gs.get_recovered_count(current_planet)
		var total = gs.get_total_count(current_planet)
		counter_label.text = "%d / %d Artifacts Found" % [rec, total]

func _show_discovery_popup(artifact_id: String) -> void:
	var gs = get_node_or_null("/root/GameState")
	var data = {}
	if gs:
		data = gs.get_artifact_data(artifact_id)
	
	popup_title.text = "ARTIFACT IDENTIFIED & RESTORED!"
	popup_name.text = data.get("name", artifact_id.capitalize())
	popup_mission.text = "Mission: %s (%s) | Status: %s" % [
		str(data.get("mission", "Unknown")),
		_format_year(data.get("year", "N/A")),
		str(data.get("status", "Active"))
	]
	popup_history.text = "[b]Purpose:[/b] %s\n\n[b]Historical Narrative:[/b] %s" % [
		data.get("purpose", ""),
		data.get("history", "")
	]
	
	discovery_popup.visible = true
	# Phase 8: animate popup open
	_animate_modal_open(discovery_popup)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func toggle_journal() -> void:
	journal_modal.visible = not journal_modal.visible
	# B7 FIX: hide scanner widget when journal is open
	radar_panel.visible = not journal_modal.visible
	if journal_modal.visible:
		_animate_modal_open(journal_modal)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_populate_journal(selected_journal_planet)
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _open_journal_to_last_discovered() -> void:
	discovery_popup.visible = false
	journal_modal.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_populate_journal(selected_journal_planet)
	if _last_discovered_id != "":
		_show_artifact_detail(_last_discovered_id)

func _populate_journal(planet: String) -> void:
	selected_journal_planet = planet
	# B6 FIX + Phase 6: active-tab highlight with token colours
	moon_tab_btn.add_theme_color_override("font_color",
		UITokens.SIGNAL_GOLD if planet == "Moon" else UITokens.PAPER_500)
	mars_tab_btn.add_theme_color_override("font_color",
		UITokens.SIGNAL_GOLD if planet == "Mars" else UITokens.PAPER_500)
	# Keep old modulate for tab background differentiation (B6 compat)
	moon_tab_btn.modulate = Color(1.0, 0.85, 0.2) if planet == "Moon" else Color(0.7, 0.75, 0.9)
	mars_tab_btn.modulate = Color(1.0, 0.85, 0.2) if planet == "Mars" else Color(0.7, 0.75, 0.9)
	for c in journal_list.get_children():
		c.queue_free()
	
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return
	
	var artifacts = gs.artifacts_data
	var entry_num := 0
	
	for id in artifacts.keys():
		var data = artifacts[id]
		if data.get("location", "").to_lower() != planet.to_lower():
			continue
		
		entry_num += 1
		var is_rec = gs.is_artifact_recovered(id)
		var cat: String = data.get("category", "")
		
		# Phase 6: row = number glyph + name/category VBox
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		journal_list.add_child(row)

		var num_lbl := Label.new()
		num_lbl.text = "%02d" % entry_num
		num_lbl.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
		num_lbl.add_theme_color_override("font_color",
			UITokens.SIGNAL_GOLD if is_rec else UITokens.PAPER_500)
		num_lbl.custom_minimum_size = Vector2(28, 0)
		row.add_child(num_lbl)

		var vb := VBoxContainer.new()
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(vb)

		var name_btn := Button.new()
		name_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		name_btn.flat = true
		name_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if is_rec:
			name_btn.text = "✓ " + data.get("name", id)
			name_btn.add_theme_color_override("font_color", UITokens.PAPER_100)
			name_btn.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
		else:
			name_btn.text = "? Unidentified Subsurface Anomaly"
			name_btn.add_theme_color_override("font_color", UITokens.PAPER_500)
			name_btn.add_theme_font_size_override("font_size", UITokens.TEXT_BODY)
		var target_id = id
		name_btn.pressed.connect(func(): _show_artifact_detail(target_id))
		vb.add_child(name_btn)

		if is_rec and cat != "":
			var cat_lbl := Label.new()
			cat_lbl.text = cat.to_upper()
			cat_lbl.add_theme_font_size_override("font_size", UITokens.TEXT_CAPTION)
			cat_lbl.add_theme_color_override("font_color", UITokens.SIGNAL_CYAN)
			vb.add_child(cat_lbl)
	
	# Select first item detail
	for id in artifacts.keys():
		if artifacts[id].get("location", "").to_lower() == planet.to_lower():
			_show_artifact_detail(id)
			break

func _show_artifact_detail(artifact_id: String) -> void:
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return
	
	var is_rec = gs.is_artifact_recovered(artifact_id)
	var data = gs.get_artifact_data(artifact_id)
	
	if is_rec:
		journal_detail_name.text = data.get("name", artifact_id)
		journal_detail_name.modulate = Color(1.0, 0.9, 0.3)
		var sources_str = ", ".join(data.get("sources", []))
	var journal_detail_text_str = "[b]Mission:[/b] %s\n[b]Year:[/b] %s\n[b]Location:[/b] %s\n[b]Status:[/b] %s\n\n[b]Purpose:[/b]\n%s\n\n[b]Historical Narrative:[/b]\n%s\n\n[b]Sources:[/b] %s" % [
			str(data.get("mission", "")),
			_format_year(data.get("year", "")),
			str(data.get("location", "")),
			str(data.get("status", "")),
			str(data.get("purpose", "")),
			str(data.get("history", "")),
			sources_str
		]
		journal_detail_text.text = journal_detail_text_str
	else:
		journal_detail_name.text = "Unidentified Anomaly"
		journal_detail_name.modulate = Color(0.7, 0.7, 0.7)
		journal_detail_text.text = "[i]This historical object remains buried beneath the lunar dust.\n\nFollow your handheld survey scanner signal to locate, excavate, and clean the artifact to uncover its identity and mission history![/i]"

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
		_pause_menu.open_settings_requested.connect(_open_settings)


func _open_pause() -> void:
	if _pause_menu:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_pause_menu.show_pause()


func _close_pause() -> void:
	if _pause_menu:
		_pause_menu.hide_pause()
		if not journal_modal.visible and not discovery_popup.visible and not completion_modal.visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _open_settings() -> void:
	var sm_scene = load("res://scenes/ui/settings_menu.tscn")
	if sm_scene:
		var sm = sm_scene.instantiate()
		add_child(sm)
		sm.settings_closed.connect(func(): sm.queue_free())
		sm.show_settings()


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
