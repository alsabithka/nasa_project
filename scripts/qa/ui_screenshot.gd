## UI screenshot harness (Phase 9 tool, used from Phase 0 on).
## Usage:
##   xvfb-run -a godot --rendering-driver opengl3 --path . --script res://scripts/qa/ui_screenshot.gd -- \
##       res://scenes/main_menu.tscn 1280 720 /tmp/out.png [frames] [action]
## `method` (optional, comma separated, each `name` or `name:arg`) is called on the instanced scene before the capture.
extends SceneTree

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	if a.size() < 4:
		push_error("usage: -- <scene> <w> <h> <out.png> [frames] [method]")
		quit(2)
		return
	var scene_path: String = a[0]
	var size := Vector2i(int(a[1]), int(a[2]))
	var out_path: String = a[3]
	var frames: int = int(a[4]) if a.size() > 4 else 20
	var method: String = a[5] if a.size() > 5 else ""
	root.size = size
	DisplayServer.window_set_size(size)
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("cannot load " + scene_path)
		quit(3)
		return
	var inst := packed.instantiate()
	root.add_child(inst)
	current_scene = inst
	_run(inst, frames, method, out_path)

func _run(inst: Node, frames: int, method: String, out_path: String) -> void:
	for i in frames:
		await process_frame
	if method != "":
		for m in method.split(","):
			var parts := m.split(":")
			var fn := parts[0]
			if inst.has_method(fn):
				if parts.size() > 1:
					inst.call(fn, float(parts[1]) if parts[1].is_valid_float() else parts[1])
				else:
					inst.call(fn)
			else:
				print("QA: no method ", fn)
			for i in 6:
				await process_frame
	for i in 10:
		await process_frame
	var img := root.get_texture().get_image()
	img.save_png(out_path)
	print("QA: saved ", out_path, " ", img.get_size())
	quit(0)
