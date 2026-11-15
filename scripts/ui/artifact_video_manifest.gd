extends RefCounted

# Echoes Beyond Earth - Artifact Video Manifest (static helper, NOT an autoload)
# Loads data/artifact_videos.json, normalises entries, parses optional SRT subtitle files
# and decides whether an artifact has a video that is allowed to play.
#
# Usage:
#   const Manifest = preload("res://scripts/ui/artifact_video_manifest.gd")
#   if Manifest.is_playable("apollo_lrv"): ...
#   var entry: Dictionary = Manifest.get_entry("apollo_lrv")

const MANIFEST_PATH := "res://data/artifact_videos.json"

# Entry status values
const STATUS_READY := "ready"                  # Produced, sourced and fact-checked. Plays in the game.
const STATUS_PLACEHOLDER := "placeholder"      # Template/test content. Plays only if settings allow it.
const STATUS_IN_PRODUCTION := "in_production"  # Never plays. Falls back to the text flashback.

const FOOTAGE_TYPES: Array[String] = [
	"archival",         # Authentic NASA/other historical film, photo or audio
	"mission_animation",# Animation produced by NASA/mission teams
	"reconstruction",   # Our own cinematic/3D reconstruction (must be disclosed)
	"data_visual",      # Maps, timelines, orbital plots, diagrams
	"gameplay",         # Captured Echoes Beyond Earth gameplay
	"placeholder",      # Test content only
]

static var _loaded: bool = false
static var _root: Dictionary = {}
static var _entry_cache: Dictionary = {}

static func reload() -> void:
	_loaded = false
	_root = {}
	_entry_cache = {}
	_ensure_loaded()

static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	if not FileAccess.file_exists(MANIFEST_PATH):
		printerr("[ArtifactVideo] Manifest not found: ", MANIFEST_PATH)
		return
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if not file:
		printerr("[ArtifactVideo] Cannot open manifest: ", MANIFEST_PATH)
		return
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not (json.data is Dictionary):
		printerr("[ArtifactVideo] Manifest JSON error on line ", json.get_error_line(), ": ", json.get_error_message())
		return
	_root = json.data

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

static func get_settings() -> Dictionary:
	_ensure_loaded()
	var defaults := {
		"play_placeholder_videos": false,
		"pause_game_during_playback": true,
		"controls_autohide_sec": 3.0,
		"chapter_card_sec": 3.2,
		"end_card_sec": 8.0,
	}
	var s: Dictionary = _root.get("settings", {})
	for k in s.keys():
		defaults[k] = s[k]
	return defaults

static func get_series() -> Dictionary:
	_ensure_loaded()
	var defaults := {
		"name": "ECHOES BEYOND EARTH",
		"tagline": "ARTIFACT ARCHIVE DOCUMENTARY SERIES",
		"closing_line": "",
	}
	var s: Dictionary = _root.get("series", {})
	for k in s.keys():
		defaults[k] = s[k]
	return defaults

static func has_entry(artifact_id: String) -> bool:
	_ensure_loaded()
	var videos: Dictionary = _root.get("videos", {})
	return videos.has(artifact_id)

static func get_artifact_ids() -> Array:
	_ensure_loaded()
	var videos: Dictionary = _root.get("videos", {})
	return videos.keys()

# Returns a normalised copy of the entry ({} if none). Subtitles are resolved
# (inline array or SRT file) and all timed lists are sorted by start time.
static func get_entry(artifact_id: String) -> Dictionary:
	_ensure_loaded()
	if _entry_cache.has(artifact_id):
		return _entry_cache[artifact_id]
	var videos: Dictionary = _root.get("videos", {})
	if not videos.has(artifact_id) or not (videos[artifact_id] is Dictionary):
		return {}

	var e: Dictionary = (videos[artifact_id] as Dictionary).duplicate(true)
	e["id"] = artifact_id
	e["status"] = str(e.get("status", STATUS_IN_PRODUCTION))
	e["artifact_type"] = str(e.get("artifact_type", "human_made"))
	e["title"] = str(e.get("title", ""))
	e["subtitle"] = str(e.get("subtitle", ""))
	e["video"] = str(e.get("video", ""))
	e["duration_sec"] = float(e.get("duration_sec", 0.0))

	var chapters: Array = e.get("chapters", [])
	chapters.sort_custom(func(a, b): return float(a.get("start", 0.0)) < float(b.get("start", 0.0)))
	e["chapters"] = chapters

	var subs: Array = []
	if e.has("subtitles_file") and str(e["subtitles_file"]) != "":
		subs = parse_srt(str(e["subtitles_file"]))
	elif e.has("subtitles"):
		subs = e["subtitles"]
	subs.sort_custom(func(a, b): return float(a.get("start", 0.0)) < float(b.get("start", 0.0)))
	e["subtitles"] = subs

	for key in ["lower_thirds", "footage", "sources"]:
		var arr: Array = e.get(key, [])
		if key != "sources":
			arr.sort_custom(func(a, b): return float(a.get("start", 0.0)) < float(b.get("start", 0.0)))
		e[key] = arr

	e["attribution"] = e.get("attribution", {})
	e["source_status"] = e.get("source_status", {})
	_entry_cache[artifact_id] = e
	return e

# True when the video file exists as an importable resource.
static func video_file_exists(entry: Dictionary) -> bool:
	var path: String = str(entry.get("video", ""))
	return path != "" and ResourceLoader.exists(path)

# Whether this artifact should play a video right now. Anything that returns
# false must fall back to the text flashback (data/flashbacks.json).
# `allow_placeholder` forces placeholder playback (used by previews/tests).
static func is_playable(artifact_id: String, allow_placeholder: bool = false) -> bool:
	var e := get_entry(artifact_id)
	if e.is_empty():
		return false
	if e["duration_sec"] <= 0.0:
		return false
	if not video_file_exists(e):
		return false
	match e["status"]:
		STATUS_READY:
			return true
		STATUS_PLACEHOLDER:
			return allow_placeholder or bool(get_settings().get("play_placeholder_videos", false))
		_:
			return false

# ---------------------------------------------------------------------------
# SRT parsing (so subtitles exported from any video editor can be dropped in)
# ---------------------------------------------------------------------------

static func parse_srt(path: String) -> Array:
	var cues: Array = []
	if not FileAccess.file_exists(path):
		printerr("[ArtifactVideo] Subtitle file not found: ", path)
		return cues
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return cues
	var text := file.get_as_text().replace("\r\n", "\n").replace("\r", "\n")
	for block in text.split("\n\n", false):
		var lines: PackedStringArray = block.strip_edges().split("\n", false)
		var ti := -1
		for i in range(lines.size()):
			if "-->" in lines[i]:
				ti = i
				break
		if ti < 0:
			continue
		var parts := lines[ti].split("-->")
		if parts.size() != 2:
			continue
		var body: PackedStringArray = lines.slice(ti + 1)
		cues.append({
			"start": _srt_time(parts[0]),
			"end": _srt_time(parts[1]),
			"text": " ".join(body).strip_edges(),
		})
	return cues

static func _srt_time(s: String) -> float:
	var t := s.strip_edges().replace(",", ".")
	var p := t.split(":")
	if p.size() != 3:
		return 0.0
	return float(p[0]) * 3600.0 + float(p[1]) * 60.0 + float(p[2])

# ---------------------------------------------------------------------------
# Validation - returns human readable problems. Empty array = OK.
# Used by the test script and by the production checklist before 'ready'.
# ---------------------------------------------------------------------------

static func validate_entry(artifact_id: String) -> Array:
	var problems: Array = []
	var e := get_entry(artifact_id)
	if e.is_empty():
		return ["no manifest entry for '%s'" % artifact_id]

	var gs = Engine.get_main_loop().root.get_node_or_null("/root/GameState") if Engine.get_main_loop() is SceneTree else null
	if gs and not gs.artifacts_data.is_empty() and not gs.artifacts_data.has(artifact_id):
		problems.append("id '%s' does not exist in data/artifacts.json" % artifact_id)

	if not [STATUS_READY, STATUS_PLACEHOLDER, STATUS_IN_PRODUCTION].has(e["status"]):
		problems.append("unknown status '%s'" % e["status"])
	if e["title"] == "":
		problems.append("missing title")
	if e["duration_sec"] <= 0.0:
		problems.append("duration_sec must be > 0 (Godot cannot read Theora length at runtime)")
	if e["video"] == "":
		problems.append("missing video path")
	elif not ResourceLoader.exists(e["video"]):
		problems.append("video file not importable/found: %s" % e["video"])
	elif not str(e["video"]).to_lower().ends_with(".ogv"):
		problems.append("video must be Ogg Theora (.ogv) - the only format Godot 4 plays natively")

	# Chapters
	var chapters: Array = e["chapters"]
	if chapters.is_empty():
		problems.append("no chapters defined")
	var last_start := -1.0
	for c in chapters:
		var st := float(c.get("start", -1.0))
		if st < 0.0 or st >= e["duration_sec"]:
			problems.append("chapter '%s' start %.2f outside 0..duration" % [c.get("id", "?"), st])
		if st <= last_start:
			problems.append("chapter '%s' start is not strictly increasing" % c.get("id", "?"))
		last_start = st
		if str(c.get("title", "")) == "":
			problems.append("chapter '%s' missing title" % c.get("id", "?"))

	# Timed lists
	for key in ["subtitles", "lower_thirds", "footage"]:
		for item in e[key]:
			var s := float(item.get("start", 0.0))
			var en := float(item.get("end", 0.0))
			if en <= s:
				problems.append("%s cue at %.2f has end <= start" % [key, s])
			if en > e["duration_sec"] + 0.5:
				problems.append("%s cue ending %.2f exceeds duration" % [key, en])
	for f in e["footage"]:
		if not FOOTAGE_TYPES.has(str(f.get("type", ""))):
			problems.append("footage type '%s' not one of %s" % [f.get("type", ""), FOOTAGE_TYPES])
		if str(f.get("credit", "")) == "":
			problems.append("footage segment at %.2f has no credit" % float(f.get("start", 0.0)))

	# Rules that only apply to a video that will be shown as real content
	if e["status"] == STATUS_READY:
		if e["sources"].is_empty():
			problems.append("'ready' videos must list at least one source with a URL")
		for s in e["sources"]:
			if str(s.get("url", "")) == "" or str(s.get("title", "")) == "":
				problems.append("every source needs 'title' and 'url'")
		if e["subtitles"].is_empty():
			problems.append("'ready' videos need subtitles")
		if e["footage"].is_empty():
			problems.append("'ready' videos must classify footage (archival / reconstruction / ...)")
		for f in e["footage"]:
			if str(f.get("type", "")) == "placeholder":
				problems.append("'ready' video still contains placeholder footage")
		for st in e["subtitles"]:
			if "[PLACEHOLDER]" in str(st.get("text", "")):
				problems.append("'ready' video still contains [PLACEHOLDER] subtitles")
				break
		if str(e["attribution"].get("credit_line", "")) == "":
			problems.append("'ready' videos need attribution.credit_line")
	return problems
