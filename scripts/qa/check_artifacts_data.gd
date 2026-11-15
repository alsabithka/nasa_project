## Merge P2 check: godot --headless --path . --script res://scripts/qa/check_artifacts_data.gd
extends SceneTree

const EXPECTED_IDS := ["apollo_lrv", "apollo_lm_descent_stage", "alsep", "sojourner", "opportunity", "ingenuity",
	"jezero_delta_clay", "seitah_olivine_basalt", "perseverance_heatshield_remnant", "martian_meteorite_shergottite",
	"pathfinder", "spirit", "viking_1", "viking_2", "phoenix", "insight"]
const RICH := ["category", "stratigraphic_layer", "discovery_depth_cm", "dimensions_cm", "mass_kg", "detection_signature",
	"geological_context", "measured_properties", "estimated_properties"]

func _initialize() -> void:
	var fails := 0
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/artifacts.json"))
	if typeof(parsed) != TYPE_DICTIONARY:
		print("FAIL: artifacts.json not valid JSON"); quit(1); return
	var list: Array = parsed["artifacts"]
	var ids: Array = []
	var moon := 0
	var mars := 0
	for a in list:
		ids.append(a["id"])
		if a["location"] == "Moon": moon += 1
		elif a["location"] == "Mars": mars += 1
		for k in RICH:
			if not a.has(k):
				print("FAIL: %s missing %s" % [a["id"], k]); fails += 1
	if ids != EXPECTED_IDS:
		print("FAIL: ids/order differ: ", ids); fails += 1
	if moon != 3 or mars != 13:
		print("FAIL: counts moon=%d mars=%d" % [moon, mars]); fails += 1
	print("artifacts: %d (moon %d / mars %d)  %s" % [list.size(), moon, mars, "PASS" if fails == 0 else "FAILED"])
	quit(1 if fails > 0 else 0)
