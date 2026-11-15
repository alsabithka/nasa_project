## Screenshot of the HUD with the player placed near an artifact.
## xvfb-run -a godot --rendering-driver opengl3 --path . --script res://scripts/qa/hud_state_shot.gd -- <scene> <w> <h> <out.png> <metres_from_artifact>
extends SceneTree

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var size := Vector2i(int(a[1]), int(a[2]))
	root.size = size
	DisplayServer.window_set_size(size)
	var inst = (load(a[0]) as PackedScene).instantiate()
	root.add_child(inst)
	for i in 30: await process_frame
	var player: Node3D = get_first_node_in_group("player")
	var arts := get_nodes_in_group("artifacts")
	var metres := float(a[4])
	if player and arts.size() > 0:
		var art: Node3D = arts[0]
		player.global_position = art.get_world_position() + Vector3(metres, 1.0, 0)
	for i in 45: await process_frame
	root.get_texture().get_image().save_png(a[3])
	print("QA: saved ", a[3])
	quit()
