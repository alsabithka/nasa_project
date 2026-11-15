extends SceneTree

# Builds the comprehensive Aerospace Telemetry master Theme and saves to res://scenes/ui/sci_fi_theme.tres

func _init() -> void:
	print("--- Building Aerospace Master Theme ---")
	var theme = Theme.new()
	
	# Palettes
	var col_bg = Color(0.0196, 0.0353, 0.0510, 0.86)
	var col_cyan = Color(0.0, 0.898, 1.0, 1.0)
	var col_turquoise = Color(0.0, 0.749, 0.647, 1.0)
	var col_amber = Color(1.0, 0.616, 0.196, 1.0)
	var col_red = Color(1.0, 0.271, 0.271, 1.0)
	var col_green = Color(0.224, 0.898, 0.549, 1.0)
	var col_white = Color(0.898, 0.949, 0.961, 1.0)
	var col_grey = Color(0.467, 0.565, 0.616, 1.0)
	
	# Load Textures
	var tex_panel = load("res://textures/ui/sci_fi_glass_panel.png")
	var tex_btn_normal = load("res://textures/ui/sci_fi_btn_normal.png")
	var tex_btn_hover = load("res://textures/ui/sci_fi_btn_hover.png")
	var tex_btn_pressed = load("res://textures/ui/sci_fi_btn_pressed.png")
	var tex_btn_disabled = load("res://textures/ui/aerospace_btn_disabled.png")
	var tex_slider_grabber = load("res://textures/ui/aerospace_slider_grabber.png")
	
	# PanelContainer / Panel
	var sb_panel = StyleBoxTexture.new()
	sb_panel.texture = tex_panel
	sb_panel.texture_margin_left = 16
	sb_panel.texture_margin_top = 16
	sb_panel.texture_margin_right = 16
	sb_panel.texture_margin_bottom = 16
	sb_panel.content_margin_left = 18
	sb_panel.content_margin_top = 14
	sb_panel.content_margin_right = 18
	sb_panel.content_margin_bottom = 14
	theme.set_stylebox("panel", "PanelContainer", sb_panel)
	theme.set_stylebox("panel", "Panel", sb_panel)
	
	# Button
	var sb_btn_n = StyleBoxTexture.new()
	sb_btn_n.texture = tex_btn_normal
	sb_btn_n.texture_margin_left = 10
	sb_btn_n.texture_margin_top = 10
	sb_btn_n.texture_margin_right = 10
	sb_btn_n.texture_margin_bottom = 10
	sb_btn_n.content_margin_left = 16
	sb_btn_n.content_margin_top = 8
	sb_btn_n.content_margin_right = 16
	sb_btn_n.content_margin_bottom = 8
	
	var sb_btn_h = StyleBoxTexture.new()
	sb_btn_h.texture = tex_btn_hover
	sb_btn_h.texture_margin_left = 10
	sb_btn_h.texture_margin_top = 10
	sb_btn_h.texture_margin_right = 10
	sb_btn_h.texture_margin_bottom = 10
	sb_btn_h.content_margin_left = 16
	sb_btn_h.content_margin_top = 8
	sb_btn_h.content_margin_right = 16
	sb_btn_h.content_margin_bottom = 8
	
	var sb_btn_p = StyleBoxTexture.new()
	sb_btn_p.texture = tex_btn_pressed
	sb_btn_p.texture_margin_left = 10
	sb_btn_p.texture_margin_top = 10
	sb_btn_p.texture_margin_right = 10
	sb_btn_p.texture_margin_bottom = 10
	sb_btn_p.content_margin_left = 16
	sb_btn_p.content_margin_top = 8
	sb_btn_p.content_margin_right = 16
	sb_btn_p.content_margin_bottom = 8
	
	var sb_btn_d = StyleBoxTexture.new()
	sb_btn_d.texture = tex_btn_disabled if tex_btn_disabled else tex_btn_normal
	sb_btn_d.texture_margin_left = 10
	sb_btn_d.texture_margin_top = 10
	sb_btn_d.texture_margin_right = 10
	sb_btn_d.texture_margin_bottom = 10
	sb_btn_d.content_margin_left = 16
	sb_btn_d.content_margin_top = 8
	sb_btn_d.content_margin_right = 16
	sb_btn_d.content_margin_bottom = 8
	sb_btn_d.modulate_color = Color(0.6, 0.6, 0.6, 0.6)
	
	var sb_btn_f = StyleBoxFlat.new()
	sb_btn_f.draw_center = false
	sb_btn_f.border_width_left = 1
	sb_btn_f.border_width_top = 1
	sb_btn_f.border_width_right = 1
	sb_btn_f.border_width_bottom = 1
	sb_btn_f.border_color = col_cyan
	sb_btn_f.corner_radius_top_left = 2
	sb_btn_f.corner_radius_top_right = 2
	sb_btn_f.corner_radius_bottom_right = 2
	sb_btn_f.corner_radius_bottom_left = 2
	
	theme.set_stylebox("normal", "Button", sb_btn_n)
	theme.set_stylebox("hover", "Button", sb_btn_h)
	theme.set_stylebox("pressed", "Button", sb_btn_p)
	theme.set_stylebox("disabled", "Button", sb_btn_d)
	theme.set_stylebox("focus", "Button", sb_btn_f)
	theme.set_color("font_color", "Button", col_cyan)
	theme.set_color("font_hover_color", "Button", col_white)
	theme.set_color("font_pressed_color", "Button", col_amber)
	theme.set_color("font_disabled_color", "Button", Color(col_grey.r, col_grey.g, col_grey.b, 0.6))
	theme.set_font_size("font_size", "Button", 14)
	
	# ProgressBar
	var sb_pb_bg = StyleBoxFlat.new()
	sb_pb_bg.bg_color = col_bg
	sb_pb_bg.border_width_left = 1
	sb_pb_bg.border_width_top = 1
	sb_pb_bg.border_width_right = 1
	sb_pb_bg.border_width_bottom = 1
	sb_pb_bg.border_color = Color(col_cyan.r, col_cyan.g, col_cyan.b, 0.5)
	sb_pb_bg.corner_radius_top_left = 2
	sb_pb_bg.corner_radius_top_right = 2
	sb_pb_bg.corner_radius_bottom_right = 2
	sb_pb_bg.corner_radius_bottom_left = 2
	
	var sb_pb_fill = StyleBoxFlat.new()
	sb_pb_fill.bg_color = col_cyan
	sb_pb_fill.corner_radius_top_left = 2
	sb_pb_fill.corner_radius_top_right = 2
	sb_pb_fill.corner_radius_bottom_right = 2
	sb_pb_fill.corner_radius_bottom_left = 2
	sb_pb_fill.shadow_color = Color(col_cyan.r, col_cyan.g, col_cyan.b, 0.35)
	sb_pb_fill.shadow_size = 3
	
	theme.set_stylebox("background", "ProgressBar", sb_pb_bg)
	theme.set_stylebox("fill", "ProgressBar", sb_pb_fill)
	
	# HSlider
	var sb_slider_bg = StyleBoxFlat.new()
	sb_slider_bg.bg_color = col_bg
	sb_slider_bg.border_width_left = 1
	sb_slider_bg.border_width_top = 1
	sb_slider_bg.border_width_right = 1
	sb_slider_bg.border_width_bottom = 1
	sb_slider_bg.border_color = Color(col_cyan.r, col_cyan.g, col_cyan.b, 0.5)
	sb_slider_bg.content_margin_top = 4
	sb_slider_bg.content_margin_bottom = 4
	
	var sb_slider_grabber_area = StyleBoxFlat.new()
	sb_slider_grabber_area.bg_color = col_cyan
	sb_slider_grabber_area.content_margin_top = 4
	sb_slider_grabber_area.content_margin_bottom = 4
	
	theme.set_stylebox("slider", "HSlider", sb_slider_bg)
	theme.set_stylebox("grabber_area", "HSlider", sb_slider_grabber_area)
	theme.set_stylebox("grabber_area_highlight", "HSlider", sb_slider_grabber_area)
	if tex_slider_grabber:
		theme.set_icon("grabber", "HSlider", tex_slider_grabber)
		theme.set_icon("grabber_highlight", "HSlider", tex_slider_grabber)
	
	# Label
	theme.set_color("font_color", "Label", col_white)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.75))
	theme.set_constant("shadow_offset_x", "Label", 1)
	theme.set_constant("shadow_offset_y", "Label", 1)
	theme.set_font_size("font_size", "Label", 14)
	
	var res = ResourceSaver.save(theme, "res://scenes/ui/sci_fi_theme.tres")
	if res == OK:
		print("Successfully saved res://scenes/ui/sci_fi_theme.tres")
	else:
		printerr("Failed to save theme! Code: ", res)
	quit(0)
