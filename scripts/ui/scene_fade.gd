class_name SceneFade
extends CanvasLayer

# Echoes Beyond Earth — Scene Fade Transition
# Fades to INK_900, changes scene, then fades back out and frees itself.
# Respects reduced motion (instant cut). Usage:
#   SceneFade.go(get_tree(), "res://scenes/levels/moon.tscn")

var _rect: ColorRect
var _target_scene: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = UITokens.LAYER_DEBUG  # topmost, covers everything
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.color = Color(UITokens.INK_900, 0.0)
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # block clicks while fading
	add_child(_rect)


func run_transition(target: String) -> void:
	_target_scene = target
	get_tree().paused = false
	var d: float = UITokens.DURATION_SLOW * SettingsStore.motion_scale()
	if d <= 0.0:
		_do_change()
		return
	var tw := create_tween()
	tw.tween_property(_rect, "color:a", 1.0, d).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(_do_change)


func _do_change() -> void:
	var tree := get_tree()
	tree.change_scene_to_file(_target_scene)
	# Let the new scene build, then reveal it and remove the overlay.
	await tree.process_frame
	await tree.process_frame
	var d: float = UITokens.DURATION_BASE * SettingsStore.motion_scale()
	if d > 0.0:
		var tw := create_tween()
		tw.tween_property(_rect, "color:a", 0.0, d).set_trans(Tween.TRANS_QUAD)
		await tw.finished
	queue_free()


## Static convenience — fade out, load next scene, fade in.
static func go(tree: SceneTree, target: String) -> void:
	var fade_scene: PackedScene = load("res://scenes/ui/scene_fade.tscn") as PackedScene
	if fade_scene == null:
		tree.paused = false
		tree.change_scene_to_file(target)
		return
	var fade: SceneFade = fade_scene.instantiate() as SceneFade
	tree.root.add_child(fade)
	fade.run_transition(target)
