extends RefCounted

# Echoes Beyond Earth — Input Setup Helper (Phase 7)
# Registers project-level InputMap actions at runtime if they don't already
# exist in project.godot. Call InputSetup.ensure() once from any _ready().
# This keeps project.godot untouched while giving all scripts a stable
# action name to query — and makes rebinding possible in the future.

class_name InputSetup

## Map of action_name → array of key constants to register as default bindings.
const DEFAULTS := {
	"gait_toggle":    [KEY_C],
	"view_toggle":    [KEY_V],
	"inspect_signal": [KEY_Q],
	"gallery_prev":   [KEY_Q, KEY_LEFT],
	"gallery_next":   [KEY_E, KEY_RIGHT],
	# Phase 6: gallery actions (replace the raw KEY_I / KEY_SPACE checks in spacecraft_gallery.gd)
	"gallery_inspect": [KEY_I],
	"gallery_rotate":  [KEY_SPACE],
}

## Phase 6: optional gamepad bindings (shoulder buttons cycle, Y inspects, X toggles rotation).
## Added only to actions this file owns; keyboard bindings above are unchanged.
const JOY_DEFAULTS := {
	"gallery_prev":    [JOY_BUTTON_LEFT_SHOULDER],
	"gallery_next":    [JOY_BUTTON_RIGHT_SHOULDER],
	"gallery_inspect": [JOY_BUTTON_Y],
	"gallery_rotate":  [JOY_BUTTON_X],
}

static func ensure() -> void:
	for action_name in DEFAULTS.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			for keycode in DEFAULTS[action_name]:
				var ev := InputEventKey.new()
				ev.physical_keycode = keycode
				InputMap.action_add_event(action_name, ev)
	for action_name in JOY_DEFAULTS.keys():
		if not InputMap.has_action(action_name):
			continue
		var has_joy := false
		for e in InputMap.action_get_events(action_name):
			if e is InputEventJoypadButton:
				has_joy = true
		if has_joy:
			continue
		for b in JOY_DEFAULTS[action_name]:
			var jb := InputEventJoypadButton.new()
			jb.button_index = b
			InputMap.action_add_event(action_name, jb)
