extends CanvasLayer

# Echoes Beyond Earth - Artifact Documentary Player
#
# The single "front door" for the post-discovery story. Given an artifact_id it:
#   1. plays the artifact's documentary video if data/artifact_videos.json has a playable entry, or
#   2. falls back to the existing text flashback (scenes/ui/flashback.tscn) if it does not.
# Either way it emits `playback_complete` exactly once so the HUD can return to gameplay.
#
# Chapters, subtitles, lower thirds, footage-type badges, sources and attribution are all drawn
# at runtime from the manifest. Do NOT burn them into the rendered video (see
# documentation/ARTIFACT_VIDEO_TEMPLATE.md).
#
# Godot limitation: Theora playback (the only native format) cannot seek and cannot report its
# length, so the progress bar is display-only and duration comes from the manifest.

const Manifest = preload("res://scripts/ui/artifact_video_manifest.gd")
const FLASHBACK_SCENE_PATH := "res://scenes/ui/flashback.tscn"

# result: "completed" (watched/ended), "skipped" (player skipped), "fallback" (text flashback ran)
signal playback_complete(artifact_id: String, result: String)

const RESULT_COMPLETED := "completed"
const RESULT_SKIPPED := "skipped"
const RESULT_FALLBACK := "fallback"

const COLOR_GOLD := Color(0.98, 0.78, 0.2)
const COLOR_CYAN := Color(0.5, 0.8, 1.0)
const COLOR_AMBER := Color(1.0, 0.65, 0.2)

const FOOTAGE_LABELS := {
	"archival": "ARCHIVAL FOOTAGE",
	"mission_animation": "MISSION ANIMATION",
	"reconstruction": "RECONSTRUCTION",
	"data_visual": "DATA VISUALIZATION",
	"gameplay": "GAMEPLAY CAPTURE",
	"placeholder": "PLACEHOLDER",
}

# Remembered for the rest of the session so the player's choice carries to the next video.
static var captions_enabled: bool = true

@export var artifact_id: String = ""
## Force placeholder entries to play (previews/tests). Normal gameplay leaves this false.
@export var allow_placeholder: bool = false

@onready var ui: Control = %UI
@onready var video: VideoStreamPlayer = %Video
@onready var top_band: PanelContainer = %TopBand
@onready var brand_label: Label = %BrandLabel
@onready var artifact_title_label: Label = %ArtifactTitleLabel
@onready var chapter_indicator: Label = %ChapterIndicator
@onready var chapter_card: VBoxContainer = %ChapterCard
@onready var chapter_number_label: Label = %ChapterNumberLabel
@onready var chapter_title_label: Label = %ChapterTitleLabel
@onready var lower_third: PanelContainer = %LowerThird
@onready var lower_third_label: Label = %LowerThirdLabel
@onready var lower_third_text: Label = %LowerThirdText
@onready var footage_badge: PanelContainer = %FootageBadge
@onready var footage_label: Label = %FootageLabel
@onready var subtitle_panel: PanelContainer = %SubtitlePanel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var paused_label: Label = %PausedLabel
@onready var control_bar: PanelContainer = %ControlBar
@onready var play_pause_button: Button = %PlayPauseButton
@onready var time_label: Label = %TimeLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var chapter_ticks: Control = %ChapterTicks
@onready var captions_button: Button = %CaptionsButton
@onready var skip_button: Button = %SkipButton
@onready var end_card: Control = %EndCard
@onready var end_brand: Label = %EndBrand
@onready var end_tagline: Label = %EndTagline
@onready var end_title: Label = %EndTitle
@onready var end_subtitle: Label = %EndSubtitle
@onready var sources_text: RichTextLabel = %SourcesText
@onready var attribution_label: Label = %AttributionLabel
@onready var closing_line: Label = %ClosingLine
@onready var auto_close_label: Label = %AutoCloseLabel
@onready var continue_button: Button = %ContinueButton
@onready var fade: ColorRect = %Fade

var entry: Dictionary = {}
var settings: Dictionary = {}
var duration: float = 0.0
var chapters: Array = []
var subtitles: Array = []
var lower_thirds: Array = []
var footage: Array = []

var is_video_mode: bool = false
var _finished: bool = false
var _exiting: bool = false
var _showing_end: bool = false
var _started: bool = false
var _frames: int = 0
var _stall_time: float = 0.0 # real seconds spent playing without ever producing a frame
const STALL_TIMEOUT_SEC := 4.0
var _max_pos: float = 0.0 # furthest playback position seen (stream_position resets to 0 after the end)
var _end_timer: float = 0.0
var _controls_idle: float = 0.0
var _prev_tree_paused: bool = false
var _paused_by_us: bool = false

var _chapter_idx: int = -1
var _subtitle_idx: int = -1
var _lower_third_idx: int = -1
var _footage_idx: int = -1
var _tweens: Dictionary = {}

func _ready() -> void:
	layer = 20 # Above all other HUD elements (same layer as the text flashback)
	process_mode = Node.PROCESS_MODE_ALWAYS

	var stream: VideoStream = null
	if Manifest.is_playable(artifact_id, allow_placeholder):
		entry = Manifest.get_entry(artifact_id)
		stream = load(str(entry["video"])) as VideoStream
		if stream == null:
			printerr("[ArtifactVideo] Could not load video stream for '%s' - using text flashback." % artifact_id)

	if stream == null:
		_start_fallback()
	else:
		_start_video(stream)

# ---------------------------------------------------------------------------
# Fallback: existing text flashback (data/flashbacks.json)
# ---------------------------------------------------------------------------

func _start_fallback() -> void:
	is_video_mode = false
	if is_instance_valid(ui):
		ui.queue_free()
	var scene := load(FLASHBACK_SCENE_PATH) as PackedScene
	if scene == null:
		_complete(RESULT_FALLBACK)
		return
	var fb := scene.instantiate()
	fb.artifact_id = artifact_id
	if fb.has_signal("flashback_complete"):
		fb.flashback_complete.connect(func(): _complete(RESULT_FALLBACK))
	add_child(fb)

# ---------------------------------------------------------------------------
# Video mode
# ---------------------------------------------------------------------------

func _start_video(stream: VideoStream) -> void:
	is_video_mode = true
	settings = Manifest.get_settings()
	var series := Manifest.get_series()
	duration = float(entry["duration_sec"])
	chapters = entry["chapters"]
	subtitles = entry["subtitles"]
	lower_thirds = entry["lower_thirds"]
	footage = entry["footage"]

	brand_label.text = str(series["name"])
	artifact_title_label.text = str(entry["title"]).to_upper()
	chapter_indicator.text = ""
	subtitle_panel.visible = false
	paused_label.visible = false
	end_card.visible = false
	chapter_card.modulate.a = 0.0
	lower_third.modulate.a = 0.0
	footage_badge.modulate.a = 0.0
	progress_bar.value = 0.0
	_update_time_label(0.0)

	captions_button.set_pressed_no_signal(captions_enabled)
	play_pause_button.pressed.connect(_toggle_pause)
	captions_button.toggled.connect(_on_captions_toggled)
	skip_button.pressed.connect(_on_skip_pressed)
	continue_button.pressed.connect(_on_skip_pressed)
	ui.gui_input.connect(_on_ui_gui_input)
	chapter_ticks.draw.connect(_draw_chapter_ticks)
	chapter_ticks.queue_redraw()

	video.stream = stream
	video.finished.connect(_on_video_finished)

	# Freeze the world while the documentary plays (this node keeps running: PROCESS_MODE_ALWAYS)
	if bool(settings.get("pause_game_during_playback", true)) and is_inside_tree():
		_prev_tree_paused = get_tree().paused
		get_tree().paused = true
		_paused_by_us = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	fade.color.a = 1.0
	_tween_property(fade, "color:a", 0.0, 0.8)
	video.play()
	_started = true

func _process(delta: float) -> void:
	if not is_video_mode or _finished or _exiting:
		return
	_frames += 1

	if _showing_end:
		_end_timer -= delta
		auto_close_label.text = "Returning to exploration in %d..." % int(ceil(maxf(_end_timer, 0.0)))
		if _end_timer <= 0.0:
			_begin_exit(RESULT_COMPLETED)
		return

	# Failsafe: if the decoder stops without the finished signal, treat it as the end.
	if _started and _frames > 20 and not video.is_playing():
		_on_video_finished()
		return

	var pos := minf(video.stream_position, duration)
	_max_pos = maxf(_max_pos, pos)

	# Watchdog: an undecodable file reports "playing" forever with position stuck at 0.
	if _max_pos < 0.05 and not video.paused:
		_stall_time += delta
		if _stall_time >= STALL_TIMEOUT_SEC:
			_video_failed()
			return
	progress_bar.value = pos / duration
	_update_time_label(pos)
	_update_chapter(pos)
	_update_subtitle(pos)
	_update_lower_third(pos)
	_update_footage(pos)
	_update_controls(delta)

func _update_time_label(pos: float) -> void:
	time_label.text = "%s / %s" % [_fmt_time(pos), _fmt_time(duration)]

func _fmt_time(t: float) -> String:
	var total := int(t)
	return "%d:%02d" % [floori(total / 60.0), total % 60]

# ---------------------------------------------------------------------------
# Timeline-driven overlays
# ---------------------------------------------------------------------------

func _find_cue(list: Array, pos: float) -> int:
	for i in range(list.size()):
		var c: Dictionary = list[i]
		if pos >= float(c.get("start", 0.0)) and pos < float(c.get("end", 0.0)):
			return i
	return -1

func _update_chapter(pos: float) -> void:
	var idx := -1
	for i in range(chapters.size()):
		if pos >= float(chapters[i].get("start", 0.0)):
			idx = i
	if idx == _chapter_idx:
		return
	_chapter_idx = idx
	if idx < 0:
		chapter_indicator.text = ""
		return
	var c: Dictionary = chapters[idx]
	var number := int(c.get("number", idx + 1))
	var title := str(c.get("title", ""))
	chapter_indicator.text = "CHAPTER %02d / %02d  ·  %s" % [number, chapters.size(), title.to_upper()]
	chapter_number_label.text = "CHAPTER %02d" % number
	chapter_title_label.text = title
	# Chapter title card: fade in, hold, fade out
	_kill_tween(chapter_card)
	chapter_card.modulate.a = 0.0
	var tw := create_tween()
	_tweens[chapter_card] = tw
	tw.tween_property(chapter_card, "modulate:a", 1.0, 0.6)
	tw.tween_interval(float(settings.get("chapter_card_sec", 3.2)))
	tw.tween_property(chapter_card, "modulate:a", 0.0, 0.8)

func _update_subtitle(pos: float) -> void:
	var idx := _find_cue(subtitles, pos)
	_subtitle_idx = idx
	if idx < 0 or not captions_enabled:
		subtitle_panel.visible = false
		return
	var text := str(subtitles[idx].get("text", ""))
	if subtitle_label.text != text:
		subtitle_label.text = text
	subtitle_panel.visible = true

func _update_lower_third(pos: float) -> void:
	var idx := _find_cue(lower_thirds, pos)
	if idx == _lower_third_idx:
		return
	_lower_third_idx = idx
	if idx >= 0:
		var c: Dictionary = lower_thirds[idx]
		lower_third_label.text = str(c.get("label", ""))
		lower_third_text.text = str(c.get("text", ""))
		_tween_property(lower_third, "modulate:a", 1.0, 0.35)
	else:
		_tween_property(lower_third, "modulate:a", 0.0, 0.35)

func _update_footage(pos: float) -> void:
	var idx := _find_cue(footage, pos)
	if idx == _footage_idx:
		return
	_footage_idx = idx
	if idx >= 0:
		var f: Dictionary = footage[idx]
		var ftype := str(f.get("type", ""))
		var label_text: String = FOOTAGE_LABELS.get(ftype, ftype.to_upper())
		var credit := str(f.get("credit", ""))
		footage_label.text = label_text if credit == "" else "%s  ·  %s" % [label_text, credit]
		# Anything that is not authentic archival material is flagged in amber.
		var authentic := ftype == "archival" or ftype == "mission_animation"
		footage_label.add_theme_color_override("font_color", COLOR_CYAN if authentic else COLOR_AMBER)
		_tween_property(footage_badge, "modulate:a", 1.0, 0.35)
	else:
		_tween_property(footage_badge, "modulate:a", 0.0, 0.35)

func _update_controls(delta: float) -> void:
	_controls_idle += delta
	var controls_visible := video.paused or _controls_idle < float(settings.get("controls_autohide_sec", 3.0))
	var target := 1.0 if controls_visible else 0.0
	control_bar.modulate.a = move_toward(control_bar.modulate.a, target, delta * 3.0)

func _draw_chapter_ticks() -> void:
	if duration <= 0.0:
		return
	var w := chapter_ticks.size.x
	var h := chapter_ticks.size.y
	for c in chapters:
		var st := float(c.get("start", 0.0))
		if st <= 0.01:
			continue
		var x := w * st / duration
		chapter_ticks.draw_rect(Rect2(x - 1.0, h * 0.5 - 8.0, 2.0, 16.0), Color(0.5, 0.8, 1.0, 0.9))

# ---------------------------------------------------------------------------
# Input / controls
# ---------------------------------------------------------------------------

func _input(event: InputEvent) -> void:
	if not is_video_mode or _finished:
		return
	if event is InputEventMouseMotion:
		_controls_idle = 0.0
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_SPACE, KEY_K:
				_toggle_pause()
			KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER:
				_on_skip_pressed()
			KEY_C:
				captions_button.button_pressed = not captions_button.button_pressed
			_:
				return
		get_viewport().set_input_as_handled()

func _on_ui_gui_input(event: InputEvent) -> void:
	# Clicking the picture toggles pause (buttons and the control bar consume their own clicks)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_controls_idle = 0.0
		_toggle_pause()

func _toggle_pause() -> void:
	if _showing_end or _exiting or _finished:
		return
	video.paused = not video.paused
	paused_label.visible = video.paused
	play_pause_button.text = "PLAY" if video.paused else "PAUSE"

func _on_captions_toggled(pressed: bool) -> void:
	captions_enabled = pressed
	if not pressed:
		subtitle_panel.visible = false

func _on_skip_pressed() -> void:
	if _showing_end:
		_begin_exit(RESULT_COMPLETED)
	else:
		_begin_exit(RESULT_SKIPPED)

# ---------------------------------------------------------------------------
# Ending
# ---------------------------------------------------------------------------

func _on_video_finished() -> void:
	if _showing_end or _exiting or _finished:
		return
	# A video that never advanced did not decode - don't show a blank end card; use the text story.
	if _max_pos < 0.5:
		_video_failed()
		return
	var end_secs := float(settings.get("end_card_sec", 8.0))
	if end_secs <= 0.0:
		_begin_exit(RESULT_COMPLETED)
		return
	_show_end_card(end_secs)

# The video could not be decoded: release the game and show the text story instead.
func _video_failed() -> void:
	printerr("[ArtifactVideo] Video for '%s' produced no frames - using text flashback." % artifact_id)
	_restore_tree_pause()
	_started = false
	if video:
		video.stop()
	_start_fallback()

func _show_end_card(end_secs: float) -> void:
	_showing_end = true
	_end_timer = end_secs
	var series := Manifest.get_series()
	var attribution: Dictionary = entry.get("attribution", {})

	end_brand.text = str(series["name"])
	end_tagline.text = str(series["tagline"])
	end_title.text = str(entry["title"])
	end_subtitle.text = str(entry["subtitle"])
	closing_line.text = str(series.get("closing_line", ""))

	var lines: PackedStringArray = []
	for s in entry["sources"]:
		var line := "• %s" % str(s.get("title", ""))
		if str(s.get("publisher", "")) != "":
			line += "  [color=#8cc8ff](%s)[/color]" % str(s["publisher"])
		lines.append(line)
	if lines.is_empty():
		lines.append("[i]No sources listed for this entry.[/i]")
	sources_text.text = "\n".join(lines)

	var attribution_lines: PackedStringArray = []
	var credit := str(attribution.get("credit_line", ""))
	if credit != "":
		attribution_lines.append(credit)
	for d in attribution.get("disclosures", []):
		attribution_lines.append(str(d))
	attribution_label.text = "\n".join(attribution_lines)

	# Hide the playback overlay, bring up the closing card
	for n in [chapter_card, lower_third, footage_badge, subtitle_panel, paused_label, control_bar, top_band]:
		n.visible = false
	end_card.modulate.a = 0.0
	end_card.visible = true
	_tween_property(end_card, "modulate:a", 1.0, 0.7)

func _begin_exit(result: String) -> void:
	if _exiting or _finished:
		return
	_exiting = true
	if video:
		video.stop()
	_kill_tween(fade)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.35)
	tw.tween_callback(_complete.bind(result))

func _complete(result: String) -> void:
	if _finished:
		return
	_finished = true
	_restore_tree_pause()
	playback_complete.emit(artifact_id, result)
	queue_free()

func _restore_tree_pause() -> void:
	if _paused_by_us and is_inside_tree():
		get_tree().paused = _prev_tree_paused
	_paused_by_us = false

func _exit_tree() -> void:
	# Safety net: never leave the game paused if this node is freed unexpectedly.
	_restore_tree_pause()

# ---------------------------------------------------------------------------
# Tween helpers
# ---------------------------------------------------------------------------

func _kill_tween(node: Object) -> void:
	if _tweens.has(node):
		var t: Tween = _tweens[node]
		if t and t.is_valid():
			t.kill()
		_tweens.erase(node)

func _tween_property(node: Object, prop: String, to: Variant, secs: float) -> void:
	_kill_tween(node)
	var tw := create_tween()
	_tweens[node] = tw
	tw.tween_property(node, prop, to, secs)
