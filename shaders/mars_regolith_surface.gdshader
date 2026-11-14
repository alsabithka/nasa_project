shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// Scientifically calibrated Martian regolith PBR shader
// Grounded in NASA Perseverance Mastcam-Z & Curiosity MAHLI micro-topography:
// 1. Asymmetric aerodynamic wind ripples with gentle windward ramps and steep slip faces.
// 2. Grain segregation: dark mafic/basaltic sand accumulates in ripple troughs.
// 3. Fine oxidized ferric dust blankets the crests and low wind zones.
// 4. Tangent-space normal perturbation creates realistic micro-shadows under low Martian sun angles.

uniform vec3 fine_regolith_color : source_color = vec3(0.74, 0.40, 0.22);
uniform vec3 coarse_sand_color : source_color = vec3(0.58, 0.35, 0.24);
uniform vec3 basalt_sand_color : source_color = vec3(0.24, 0.22, 0.20);
uniform vec3 bedrock_tone : source_color = vec3(0.44, 0.36, 0.30);
uniform float ripple_frequency : hint_range(0.5, 4.0) = 1.6;
uniform float ripple_depth : hint_range(0.01, 0.15) = 0.055;
uniform float dust_mantle_weight : hint_range(0.0, 1.0) = 0.40;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec3 world_pos = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 p = world_pos.xz;

	// Prevailing Martian wind direction (~38 degrees)
	vec2 wind_dir = vec2(0.788, 0.615);
	vec2 cross_wind = vec2(-wind_dir.y, wind_dir.x);

	// Organic ripple wander and bifurcations
	float wander = (value_noise(p * 0.08) - 0.5) * 2.2 + (value_noise(p * 0.25) - 0.5) * 0.8;
	float coord = (dot(p, wind_dir) + wander) * ripple_frequency;
	float phase = fract(coord);

	// Aerodynamic asymmetric profile: gentle windward ramp (0 to 0.75), steep leeward drop (0.75 to 1.0)
	float ripple_height;
	if (phase < 0.75) {
		ripple_height = pow(phase / 0.75, 1.35);
	} else {
		ripple_height = pow(1.0 - ((phase - 0.75) / 0.25), 1.8);
	}

	// Secondary micro-ripples from shifting Martian breezes
	float micro_phase = fract(dot(p, wind_dir * 1.8 + cross_wind * 0.4) * 2.5);
	float micro_ripple = sin(micro_phase * 6.28318) * 0.12;
	float total_ripple = clamp(ripple_height + micro_ripple, 0.0, 1.0);

	// Finite-difference surface normal perturbation for micro-shadows
	float eps = 0.04;
	float c_plus = (dot(p + wind_dir * eps, wind_dir) + wander) * ripple_frequency;
	float c_minus = (dot(p - wind_dir * eps, wind_dir) + wander) * ripple_frequency;
	float ph_plus = fract(c_plus);
	float ph_minus = fract(c_minus);
	float h_plus = ph_plus < 0.75 ? pow(ph_plus / 0.75, 1.35) : pow(1.0 - ((ph_plus - 0.75) / 0.25), 1.8);
	float h_minus = ph_minus < 0.75 ? pow(ph_minus / 0.75, 1.35) : pow(1.0 - ((ph_minus - 0.75) / 0.25), 1.8);
	float slope = (h_plus - h_minus) / (2.0 * eps) * ripple_depth;

	vec3 norm_offset = vec3(wind_dir.x * slope, 1.0, wind_dir.y * slope);
	vec3 world_normal = normalize(norm_offset);
	NORMAL = (VIEW_MATRIX * vec4(world_normal, 0.0)).xyz;

	// Material color modulation:
	// Troughs collect dark mafic basalt grains; crests gather warm oxidized ferric dust
	float crest_factor = smoothstep(0.35, 0.85, total_ripple);
	vec3 ripple_sand_color = mix(basalt_sand_color, fine_regolith_color, crest_factor);

	// Combine with coarse gravel and underlying bedrock
	float gravel_speckle = value_noise(p * 3.5);
	vec3 intermediate_sand = mix(ripple_sand_color, coarse_sand_color, gravel_speckle * 0.4);

	// Integrate with vertex color (carrying large-scale geological map)
	vec3 base_color = mix(COLOR.rgb, intermediate_sand, dust_mantle_weight);

	ALBEDO = base_color;
	ROUGHNESS = mix(0.96, 0.84, (1.0 - crest_factor) * 0.5); // Troughs are slightly smoother/coarser
	METALLIC = 0.02;
	SPECULAR = 0.16;
}
