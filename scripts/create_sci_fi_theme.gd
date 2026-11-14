extends SceneTree

func _init() -> void:
	print("--- Constructing Master Sci-Fi Holographic Theme ---")
	
	var theme = Theme.new()
	
	# Load 9-slice textures
	var glass_tex = load("res://textures/ui/sci_fi_glass_panel.png")
	var orange_tex = load("res://textures/ui/sci_fi_orange_panel.png")
	var btn_normal_tex = load("res://textures/ui/sci_fi_btn_normal.png")
	var btn_hover_tex = load("res://textures/ui/sci_fi_btn_hover.png")
	var btn_pressed_tex = load("res://textures/ui/sci_fi_btn_pressed.png")
	
	# 1. PanelContainer & Panel
	var style_panel = StyleBoxTexture.new()
	style_panel.texture = glass_tex
	style_panel.texture_margin_left = 16
	style_panel.texture_margin_top = 16
	style_panel.texture_margin_right = 16
	style_panel.texture_margin_bottom = 16
	style_panel.content_margin_left = 18
	style_panel.content_margin_top = 14
	style_panel.content_margin_right = 18
	style_panel.content_margin_bottom = 14
	theme.set_stylebox("panel", "PanelContainer", style_panel)
	theme.set_stylebox("panel", "Panel", style_panel)
	
	# 2. Buttons (Normal, Hover, Pressed, Focus, Disabled)
	var btn_norm = StyleBoxTexture.new()
	btn_norm.texture = btn_normal_tex
	btn_norm.texture_margin_left = 10
	btn_norm.texture_margin_top = 10
	btn_norm.texture_margin_right = 10
	btn_norm.texture_margin_bottom = 10
	btn_norm.content_margin_left = 16
	btn_norm.content_margin_top = 8
	btn_norm.content_margin_right = 16
	btn_norm.content_margin_bottom = 8
	theme.set_stylebox("normal", "Button", btn_norm)
	
	var btn_hov = StyleBoxTexture.new()
	btn_hov.texture = btn_hover_tex
	btn_hov.texture_margin_left = 10
	btn_hov.texture_margin_top = 10
	btn_hov.texture_margin_right = 10
	btn_hov.texture_margin_bottom = 10
	btn_hov.content_margin_left = 16
	btn_hov.content_margin_top = 8
	btn_hov.content_margin_right = 16
	btn_hov.content_margin_bottom = 8
	theme.set_stylebox("hover", "Button", btn_hov)
	
	var btn_press = StyleBoxTexture.new()
	btn_press.texture = btn_pressed_tex
	btn_press.texture_margin_left = 10
	btn_press.texture_margin_top = 10
	btn_press.texture_margin_right = 10
	btn_press.texture_margin_bottom = 10
	btn_press.content_margin_left = 16
	btn_press.content_margin_top = 8
	btn_press.content_margin_right = 16
	btn_press.content_margin_bottom = 8
	theme.set_stylebox("pressed", "Button", btn_press)
	
	var btn_focus = StyleBoxFlat.new()
	btn_focus.draw_center = false
	btn_focus.border_width_left = 2
	btn_focus.border_width_top = 2
	btn_focus.border_width_right = 2
	btn_focus.border_width_bottom = 2
	btn_focus.border_color = Color(0.0, 1.0, 1.0, 0.9)
	theme.set_stylebox("focus", "Button", btn_focus)
	
	var btn_dis = StyleBoxTexture.new()
	btn_dis.texture = btn_normal_tex
	btn_dis.modulate_color = Color(0.5, 0.5, 0.6, 0.4)
	btn_dis.texture_margin_left = 10
	btn_dis.texture_margin_top = 10
	btn_dis.texture_margin_right = 10
	btn_dis.texture_margin_bottom = 10
	btn_dis.content_margin_left = 16
	btn_dis.content_margin_top = 8
	btn_dis.content_margin_right = 16
	btn_dis.content_margin_bottom = 8
	theme.set_stylebox("disabled", "Button", btn_dis)
	
	theme.set_color("font_color", "Button", Color(0.15, 0.90, 1.0))
	theme.set_color("font_hover_color", "Button", Color(1.0, 1.0, 1.0))
	theme.set_color("font_pressed_color", "Button", Color(1.0, 0.65, 0.1))
	theme.set_color("font_disabled_color", "Button", Color(0.4, 0.5, 0.6))
	theme.set_font_size("font_size", "Button", 15)
	
	# 3. Label
	theme.set_color("font_color", "Label", Color(0.85, 0.94, 1.0))
	theme.set_color("font_shadow_color", "Label", Color(0.0, 0.4, 0.8, 0.4))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_font_size("font_size", "Label", 15)
	
	# 4. ProgressBar (Tactical Neon Fill)
	var prog_bg = StyleBoxFlat.new()
	prog_bg.bg_color = Color(0.02, 0.05, 0.09, 0.75)
	prog_bg.border_width_left = 1
	prog_bg.border_width_top = 1
	prog_bg.border_width_right = 1
	prog_bg.border_width_bottom = 1
	prog_bg.border_color = Color(0.0, 0.8, 1.0, 0.6)
	prog_bg.corner_radius_top_left = 4
	prog_bg.corner_radius_top_right = 4
	prog_bg.corner_radius_bottom_right = 4
	prog_bg.corner_radius_bottom_left = 4
	theme.set_stylebox("background", "ProgressBar", prog_bg)
	
	var prog_fill = StyleBoxFlat.new()
	prog_fill.bg_color = Color(0.0, 0.95, 1.0, 0.95)
	prog_fill.corner_radius_top_left = 3
	prog_fill.corner_radius_top_right = 3
	prog_fill.corner_radius_bottom_right = 3
	prog_fill.corner_radius_bottom_left = 3
	prog_fill.shadow_color = Color(0.0, 0.95, 1.0, 0.4)
	prog_fill.shadow_size = 4
	theme.set_stylebox("fill", "ProgressBar", prog_fill)
	
	# Save theme to file
	var err = ResourceSaver.save(theme, "res://scenes/ui/sci_fi_theme.tres")
	print("Saved res://scenes/ui/sci_fi_theme.tres result: ", err)
	quit(0)
