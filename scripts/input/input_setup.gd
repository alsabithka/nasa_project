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
}

static func ensure() -> void:
	for action_name in DEFAULTS.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			for keycode in DEFAULTS[action_name]:
				var ev := InputEventKey.new()
				ev.physical_keycode = keycode
				InputMap.action_add_event(action_name, ev)
