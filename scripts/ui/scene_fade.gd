extends CanvasLayer

# Echoes Beyond Earth — Scene Fade Transition (Phase 8)
# A full-screen INK_900 overlay that fades in, calls the scene change,
# then fades out in the new scene.
# Usage:
#   SceneFade.go(get_tree(), "res://scenes/levels/moon.tscn")

class_name SceneFade

const UITokens = preload("res://scripts/ui/ui_tokens.gd")

var _rect: ColorRect
var _target_scene: String = ""

func _ready() -> void:
	layer = UITokens.LAYER_DEBUG  # 50 — topmost, covers everything
	_rect = ColorRect.new()
	_rect.anchors_preset = Control.PRESET_FULL_RECT
	_rect.color = Color(UITokens.INK_900, 0.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)


func run_transition(target: String) -> void:
	_target_scene = target
	var tw := create_tween()
	tw.tween_property(_rect, "color:a", 1.0, UITokens.DURATION_SLOW).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(_do_change)


func _do_change() -> void:
	get_tree().change_scene_to_file(_target_scene)


## Static convenience — fades current scene out, loads next, fades in.
static func go(tree: SceneTree, target: String) -> void:
	var fade_scene := load("res://scenes/ui/scene_fade.tscn")
	if not fade_scene:
		# Fallback: instant change
		tree.change_scene_to_file(target)
		return
	var fade: SceneFade = fade_scene.instantiate()
	tree.root.add_child(fade)
	fade.run_transition(target)
