extends SceneTree

# Verification for the artifact documentary system.
#   godot --headless --path . -s res://scripts/test_artifact_video_system.gd
#   godot --headless --path . -s res://scripts/test_artifact_video_system.gd -- full
# "full" additionally lets the 24 s placeholder play to its natural end + closing card (~35 s).

const Manifest = preload("res://scripts/ui/artifact_video_manifest.gd")
const PLAYER_SCENE := "res://scenes/ui/artifact_video_player.tscn"

var failures: int = 0

func _check(cond: bool, label: String) -> void:
	if cond:
		print("  PASS  ", label)
	else:
		failures += 1
		printerr("  FAIL  ", label)

func _init() -> void:
	print("==================================================")
	print("RUNNING VERIFICATION: ARTIFACT VIDEO SYSTEM")
	print("==================================================")
	call_deferred("_run")

func _wait(secs: float) -> void:
	await create_timer(secs, true).timeout

func _make_player(id: String, placeholder: bool) -> Node:
	var p = (load(PLAYER_SCENE) as PackedScene).instantiate()
	p.artifact_id = id
	p.allow_placeholder = placeholder
	return p

func _run() -> void:
	await process_frame # let autoloads finish _ready
	var full := OS.get_cmdline_user_args().has("full")

	# ---- 1. Manifest ----------------------------------------------------
	print("\n--- 1. Manifest ---")
	Manifest.reload()
	_check(Manifest.has_entry("apollo_lrv"), "manifest has apollo_lrv")
	_check(not Manifest.has_entry("alsep"), "manifest has no alsep entry (uses fallback)")
	var problems := Manifest.validate_entry("apollo_lrv")
	_check(problems.is_empty(), "apollo_lrv placeholder entry validates (%s)" % str(problems))
	var e := Manifest.get_entry("apollo_lrv")
	_check(e["chapters"].size() == 6, "six chapters")
	_check(e["subtitles"].size() > 0 and e["footage"].size() > 0, "subtitles and footage classification present")
	_check(not Manifest.is_playable("apollo_lrv"), "placeholder does NOT play in normal gameplay")
	_check(Manifest.is_playable("apollo_lrv", true), "placeholder plays when explicitly allowed")
	_check(not Manifest.is_playable("alsep"), "artifact without entry is not playable")
	_check(not Manifest.is_playable("no_such_artifact"), "unknown id is not playable")
	_check(Manifest.validate_entry("no_such_artifact").size() == 1, "validate reports missing entry")
	# Every entry in the manifest (including future 'ready' videos) must pass validation
	for id in Manifest.get_artifact_ids():
		var gs = root.get_node_or_null("/root/GameState")
		_check(gs != null and gs.artifacts_data.has(id), "manifest id '%s' exists in artifacts.json" % id)
		var entry_problems := Manifest.validate_entry(id)
		_check(entry_problems.is_empty(), "manifest entry '%s' passes validation %s" % [id, str(entry_problems)])

	# SRT parsing
	var srt_path := "user://test_cues.srt"
	var f := FileAccess.open(srt_path, FileAccess.WRITE)
	f.store_string("1\n00:00:01,500 --> 00:00:03,250\nFirst line\nsecond line\n\n2\n00:01:02,000 --> 00:01:04,000\nSecond cue\n")
	f.close()
	var cues := Manifest.parse_srt(srt_path)
	_check(cues.size() == 2, "SRT parsed into 2 cues")
	_check(is_equal_approx(cues[0]["start"], 1.5) and is_equal_approx(cues[0]["end"], 3.25), "SRT timestamps parsed")
	_check(cues[0]["text"] == "First line second line", "SRT multi-line text joined")
	_check(is_equal_approx(cues[1]["start"], 62.0), "SRT minutes parsed")

	# ---- 2. Fallback to text flashback -----------------------------------
	print("\n--- 2. Fallback ---")
	var results: Array = []
	var fb_player = _make_player("lunar_ferroan_anorthosite", false) # no video, no flashback entry
	fb_player.playback_complete.connect(func(id, r): results.append([id, r]))
	root.add_child(fb_player)
	await _wait(0.3)
	_check(results.size() == 1 and results[0][1] == "fallback", "artifact with no story completes immediately via fallback")
	_check(not paused, "tree not paused after fallback")

	results.clear()
	var fb2 = _make_player("apollo_lrv", false) # has placeholder video but gameplay flag is off -> flashback text
	fb2.playback_complete.connect(func(id, r): results.append([id, r]))
	root.add_child(fb2)
	await _wait(0.3)
	_check(not fb2.is_video_mode, "placeholder entry falls back to flashback in normal gameplay")
	_check(fb2.get_child_count() > 0 and fb2.get_children().any(func(n): return n.get_script() != null and "flashback_system" in n.get_script().resource_path), "text flashback instantiated")
	_check(not paused, "fallback flashback does not pause the tree")
	fb2.queue_free()
	await process_frame

	# ---- 3. Video playback ----------------------------------------------
	print("\n--- 3. Video playback ---")
	results.clear()
	var pl = _make_player("apollo_lrv", true)
	pl.playback_complete.connect(func(id, r): results.append([id, r]))
	root.add_child(pl)
	await _wait(2.0)
	_check(pl.is_video_mode, "video mode active")
	_check(paused, "game tree paused during playback")
	_check(pl.video.is_playing(), "video is playing")
	var pos1: float = pl.video.stream_position
	_check(pos1 > 0.5, "stream position advances (%.2f s)" % pos1)
	_check(pl._chapter_idx == 0, "chapter 1 active")
	_check(pl.chapter_indicator.text.begins_with("CHAPTER 01 / 06"), "chapter indicator text: %s" % pl.chapter_indicator.text)
	_check(pl.progress_bar.value > 0.0, "progress bar advancing")
	_check(pl.subtitle_panel.visible and pl.subtitle_label.text.begins_with("[PLACEHOLDER]"), "subtitle shown")
	_check(pl.footage_label.text.contains("PLACEHOLDER"), "footage badge flags placeholder footage")

	# pause / resume
	pl._toggle_pause()
	await _wait(0.2)
	var frozen: float = pl.video.stream_position
	await _wait(0.6)
	_check(pl.video.paused and absf(pl.video.stream_position - frozen) < 0.05, "pause freezes playback")
	_check(pl.paused_label.visible and pl.play_pause_button.text == "PLAY", "paused indicator shown")
	pl._toggle_pause()
	await _wait(0.8)
	_check(pl.video.stream_position > frozen + 0.3, "resume continues playback")

	# captions toggle
	pl.captions_button.button_pressed = false
	await _wait(0.2)
	_check(not pl.subtitle_panel.visible, "captions can be switched off")
	pl.captions_button.button_pressed = true

	# skip
	pl._on_skip_pressed()
	await _wait(1.0)
	_check(results.size() == 1 and results[0][1] == "skipped", "skip emits playback_complete(skipped)")
	_check(not paused, "tree unpaused after skip")
	_check(not is_instance_valid(pl) or pl.is_queued_for_deletion(), "player freed after skip")

	# ---- 4. HUD integration ---------------------------------------------
	print("\n--- 4. HUD integration ---")
	var hud = (load("res://scenes/ui/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	await process_frame
	hud._trigger_flashback("alsep")
	await process_frame
	var story = hud.get_children().filter(func(n): return n.get_script() != null and "artifact_video_player" in n.get_script().resource_path)
	_check(story.size() == 1, "HUD spawned the artifact story player")
	_check(story.size() == 1 and story[0].artifact_id == "alsep", "player received the discovered artifact id")
	hud._on_popup_closed() # also exercise the real popup-closed path
	await process_frame
	hud.queue_free()
	await process_frame

	# ---- 5. Natural end (optional) --------------------------------------
	if full:
		print("\n--- 5. Natural end of video + closing card ---")
		results.clear()
		var pf = _make_player("apollo_lrv", true)
		pf.playback_complete.connect(func(id, r): results.append([id, r]))
		root.add_child(pf)
		await _wait(26.5)
		_check(pf._showing_end and pf.end_card.visible, "closing card shown after video ends")
		_check(pf.end_title.text == "Lunar Roving Vehicle", "closing card carries the artifact title")
		await _wait(9.5)
		_check(results.size() == 1 and results[0][1] == "completed", "closing card auto-continues (completed)")
		_check(not paused, "tree unpaused after natural end")

	print("\n==================================================")
	if failures == 0:
		print("ALL ARTIFACT VIDEO CHECKS PASSED")
	else:
		printerr("%d CHECK(S) FAILED" % failures)
	print("==================================================")
	quit(1 if failures > 0 else 0)
