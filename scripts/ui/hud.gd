extends Control

# Echoes Beyond Earth - In-Game HUD, Aerospace Tactical Radar, Mystery Scanner & In-Game Config

@export var current_planet: String = "Moon"

# UI Nodes
@onready var location_label: Label = $TopBar/MarginContainer/HBoxContainer/LocationLabel
@onready var counter_label: Label = $TopBar/MarginContainer/HBoxContainer/CounterBadge/CounterLabel
@onready var journal_button: Button = $TopBar/MarginContainer/HBoxContainer/JournalButton
@onready var menu_button: Button = $TopBar/MarginContainer/HBoxContainer/MenuButton

# Resource Counters
@onready var energy_label: Label = get_node_or_null("TopBar/MarginContainer/HBoxContainer/EnergyPanel/HBox/EnergyLabel")
@onready var minerals_label: Label = get_node_or_null("TopBar/MarginContainer/HBoxContainer/MineralsPanel/HBox/MineralsLabel")

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

# In-Game Settings Modal (Pause Menu)
@onready var settings_modal: PanelContainer = get_node_or_null("SettingsModal")
@onready var close_settings_btn: Button = get_node_or_null("SettingsModal/MarginContainer/VBox/Header/CloseSettingsBtn")
@onready var resume_btn: Button = get_node_or_null("SettingsModal/MarginContainer/VBox/ResumeBtn")
@onready var restart_btn: Button = get_node_or_null("SettingsModal/MarginContainer/VBox/RestartBtn")
@onready var main_menu_btn: Button = get_node_or_null("SettingsModal/MarginContainer/VBox/MainMenuBtn")
@onready var volume_slider: HSlider = get_node_or_null("SettingsModal/MarginContainer/VBox/VolumeHBox/VolumeSlider")
@onready var volume_val_label: Label = get_node_or_null("SettingsModal/MarginContainer/VBox/VolumeHBox/VolumeValue")
@onready var sens_slider: HSlider = get_node_or_null("SettingsModal/MarginContainer/VBox/SensitivityHBox/SensSlider")
@onready var sens_val_label: Label = get_node_or_null("SettingsModal/MarginContainer/VBox/SensitivityHBox/SensValue")
@onready var fullscreen_btn: Button = get_node_or_null("SettingsModal/MarginContainer/VBox/FullscreenBtn")

var selected_journal_planet: String = "Moon"
var _last_discovered_id: String = ""

func _ready() -> void:
	_update_header()
	_connect_gamestate()
	_connect_scanner()
	_setup_buttons()
	_setup_settings_modal()
	
	if discovery_popup: discovery_popup.visible = false
	if journal_modal: journal_modal.visible = false
	if completion_modal: completion_modal.visible = false
	if settings_modal: settings_modal.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_journal"):
		toggle_journal()
	elif event.is_action_pressed("ui_cancel"):
		toggle_settings()

func _setup_buttons() -> void:
	journal_button.pressed.connect(toggle_journal)
	menu_button.pressed.connect(toggle_settings)
	popup_close_btn.pressed.connect(_on_popup_closed)
	popup_journal_btn.pressed.connect(_open_journal_to_last_discovered)
	journal_close_btn.pressed.connect(func(): journal_modal.visible = false)
	
	moon_tab_btn.pressed.connect(func(): _populate_journal("Moon"))
	mars_tab_btn.pressed.connect(func(): _populate_journal("Mars"))
	
	if continue_btn:
		continue_btn.pressed.connect(func(): completion_modal.visible = false)
	if travel_mars_btn:
		travel_mars_btn.pressed.connect(_travel_to_mars)

func _setup_settings_modal() -> void:
	if not settings_modal:
		return
	
	if close_settings_btn:
		close_settings_btn.pressed.connect(toggle_settings)
	if resume_btn:
		resume_btn.pressed.connect(toggle_settings)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart_pressed)
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_menu_pressed)
	
	if volume_slider:
		volume_slider.value_changed.connect(func(val):
			AudioServer.set_bus_volume_db(0, linear_to_db(val))
			if volume_val_label: volume_val_label.text = "%d%%" % int(val * 100.0)
		)
	
	if sens_slider:
		sens_slider.value_changed.connect(func(val):
			var player = get_tree().get_first_node_in_group("player")
			if player and "mouse_sensitivity" in player:
				player.mouse_sensitivity = 0.002 * val
			if sens_val_label: sens_val_label.text = "%.1fx" % val
		)
	
	if fullscreen_btn:
		fullscreen_btn.pressed.connect(func():
			var mode = DisplayServer.window_get_mode()
			if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
				fullscreen_btn.text = "[ FULLSCREEN: OFF ]"
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
				fullscreen_btn.text = "[ FULLSCREEN: ON ]"
		)

func toggle_settings() -> void:
	if not settings_modal:
		_on_menu_pressed()
		return
	
	settings_modal.visible = not settings_modal.visible
	if settings_modal.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("release_mouse"):
			player.release_mouse()
	else:
		if not journal_modal.visible and not discovery_popup.visible and not completion_modal.visible:
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_method("capture_mouse"):
				player.capture_mouse()

func _on_restart_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var cur_scene = get_tree().current_scene
	if cur_scene:
		get_tree().reload_current_scene()

func _connect_gamestate() -> void:
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return
	
	gs.artifact_recovered.connect(_on_artifact_recovered)
	gs.mission_completed.connect(_on_mission_completed)
	if gs.has_signal("resources_updated"):
		gs.resources_updated.connect(_on_resources_updated)
	
	_on_resources_updated(gs.get_energy(), gs.max_energy, gs.get_minerals())
	_update_header()

func _on_resources_updated(energy_val: float, max_energy_val: float, minerals_val: int) -> void:
	if energy_label:
		var pct = int((energy_val / max(1.0, max_energy_val)) * 100.0)
		energy_label.text = "%d%%" % pct
		if pct < 20:
			energy_label.modulate = AerospaceTheme.COLOR_CRITICAL
		else:
			energy_label.modulate = AerospaceTheme.COLOR_CYAN
	
	if minerals_label:
		minerals_label.text = "%s kg" % _format_number(minerals_val)

func _format_number(n: int) -> String:
	var s = str(n)
	var out = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = "," + out
	return out

func _connect_scanner() -> void:
	var scanners = get_tree().get_nodes_in_group("scanner")
	for s in scanners:
		if s.has_signal("scan_updated"):
			s.scan_updated.connect(_on_scan_updated)

# Mystery Scanner: Proximity and Signal Strength only, NEVER reveals artifact identity!
func _on_scan_updated(target_id: String, distance: float, signal_strength: float) -> void:
	if target_id == "" or distance > 65.0:
		distance_label.text = "-- m"
		strength_bar.value = 0
		target_name_label.text = "SEARCHING FOR SIGNALS..."
		target_name_label.modulate = AerospaceTheme.COLOR_TEXT_SECONDARY
		distance_label.modulate = AerospaceTheme.COLOR_TEXT_SECONDARY
		if compass_needle:
			compass_needle.rotation = 0.0
		return
	
	distance_label.text = "%.1f m" % distance
	strength_bar.value = signal_strength * 100.0
	
	# Mystery-based signal categorization with aerospace telemetry colors
	if distance <= 4.0:
		target_name_label.text = "● ANOMALY BENEATH SURFACE — DIG HERE"
		target_name_label.modulate = AerospaceTheme.COLOR_STATUS_GREEN
		distance_label.modulate = AerospaceTheme.COLOR_STATUS_GREEN
	elif distance < 15.0:
		target_name_label.text = "▲ STRONG SUBSURFACE ANOMALY"
		target_name_label.modulate = AerospaceTheme.COLOR_AMBER
		distance_label.modulate = AerospaceTheme.COLOR_AMBER
	elif distance < 35.0:
		target_name_label.text = "◆ MODERATE SIGNAL DETECTED"
		target_name_label.modulate = AerospaceTheme.COLOR_CYAN
		distance_label.modulate = AerospaceTheme.COLOR_CYAN
	else:
		target_name_label.text = "~ FAINT SIGNAL DETECTED"
		target_name_label.modulate = AerospaceTheme.COLOR_TEXT_SECONDARY
		distance_label.modulate = AerospaceTheme.COLOR_TEXT_SECONDARY

func _on_artifact_recovered(artifact_id: String) -> void:
	_last_discovered_id = artifact_id
	_update_header()
	_show_discovery_popup(artifact_id)
	if journal_modal.visible:
		_populate_journal(selected_journal_planet)

func _on_popup_closed() -> void:
	discovery_popup.visible = false
	if _last_discovered_id != "":
		_trigger_flashback(_last_discovered_id)

func _trigger_flashback(artifact_id: String) -> void:
	var flashback_scene = load("res://scenes/ui/flashback.tscn")
	if flashback_scene:
		var fb = flashback_scene.instantiate()
		fb.artifact_id = artifact_id
		if fb.has_signal("flashback_complete"):
			fb.flashback_complete.connect(_on_flashback_complete)
		add_child(fb)

func _on_flashback_complete() -> void:
	if not journal_modal.visible and not discovery_popup.visible and not completion_modal.visible and (not settings_modal or not settings_modal.visible):
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("capture_mouse"):
			player.capture_mouse()

func _on_mission_completed(planet: String) -> void:
	if completion_modal:
		completion_modal.visible = true
		if planet == "Moon":
			completion_desc.text = "All Apollo lunar artifacts cataloged and preserved! Deep space trajectory to Mars unlocked."
			if travel_mars_btn:
				travel_mars_btn.visible = true
		else:
			completion_desc.text = "Mission complete! All historical Martian survey equipment successfully cataloged."
			if travel_mars_btn:
				travel_mars_btn.visible = false

func _travel_to_mars() -> void:
	completion_modal.visible = false
	get_tree().change_scene_to_file("res://scenes/levels/mars.tscn")

func _update_header() -> void:
	if location_label:
		location_label.text = "SECTOR: %s // TAURUS-LITTROW [EVA-1]" % current_planet.to_upper()
	var gs = get_node_or_null("/root/GameState")
	if gs:
		var rec = gs.get_recovered_count(current_planet)
		var total = gs.get_total_count(current_planet)
		if counter_label:
			counter_label.text = "RECOVERY: %d / %d ARTIFACTS" % [rec, total]
		_on_resources_updated(gs.get_energy(), gs.max_energy, gs.get_minerals())

func _show_discovery_popup(artifact_id: String) -> void:
	var gs = get_node_or_null("/root/GameState")
	var data = {}
	if gs:
		data = gs.get_artifact_data(artifact_id)
	
	popup_title.text = "// NASA EXPEDITION LOG: ARTIFACT CATALOGED //"
	popup_name.text = data.get("name", artifact_id.capitalize())
	popup_mission.text = "Mission: %s (%s) | Status: %s" % [
		str(data.get("mission", "Unknown")),
		str(data.get("year", "N/A")),
		str(data.get("status", "Active"))
	]
	popup_history.text = "[b]Scientific Purpose:[/b] %s\n\n[b]Historical Narrative:[/b] %s" % [
		data.get("purpose", ""),
		data.get("history", "")
	]
	
	discovery_popup.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func toggle_journal() -> void:
	journal_modal.visible = not journal_modal.visible
	if journal_modal.visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_populate_journal(selected_journal_planet)
	else:
		if not settings_modal or not settings_modal.visible:
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
	for c in journal_list.get_children():
		c.queue_free()
	
	var gs = get_node_or_null("/root/GameState")
	if not gs:
		return
	
	var artifacts = gs.artifacts_data
	
	for id in artifacts.keys():
		var data = artifacts[id]
		if data.get("location", "").to_lower() != planet.to_lower():
			continue
		
		var is_rec = gs.is_artifact_recovered(id)
		
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(0, 48)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		if is_rec:
			btn.text = " [✓] " + data.get("name", id)
			btn.modulate = AerospaceTheme.COLOR_STATUS_GREEN
		else:
			btn.text = " [ ? ] Unidentified Subsurface Anomaly"
			btn.modulate = AerospaceTheme.COLOR_TEXT_SECONDARY
		
		var target_id = id
		btn.pressed.connect(func(): _show_artifact_detail(target_id))
		journal_list.add_child(btn)
	
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
		journal_detail_name.modulate = AerospaceTheme.COLOR_AMBER
		var sources_str = ", ".join(data.get("sources", []))
		journal_detail_text.text = "[b]Mission:[/b] %s\n[b]Year:[/b] %s\n[b]Site Location:[/b] %s\n[b]Telemetry Status:[/b] %s\n\n[b]Scientific Purpose:[/b]\n%s\n\n[b]Historical Narrative:[/b]\n%s\n\n[b]Verified NASA Archives:[/b] %s" % [
			str(data.get("mission", "")),
			str(data.get("year", "")),
			str(data.get("location", "")),
			str(data.get("status", "")),
			str(data.get("purpose", "")),
			str(data.get("history", "")),
			sources_str
		]
	else:
		journal_detail_name.text = "Unidentified Subsurface Anomaly"
		journal_detail_name.modulate = AerospaceTheme.COLOR_CYAN
		journal_detail_text.text = "[i]This historical lunar asset remains embedded beneath the regolith mantle.\n\nUse your RF Proximity Scanner & Tactical Radar to pinpoint coordinates, perform ultrasonic regolith decontamination, and preserve the artifact for the archives.[/i]"

func _on_menu_pressed() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
