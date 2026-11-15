shader_type spatial;
render_mode cull_back;

uniform vec4 albedo_color : source_color = vec4(0.98, 0.82, 0.15, 1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.45;
uniform float coverage : hint_range(0.0, 1.0) = 0.0;
uniform float curve : hint_range(0.0, 0.1) = 0.035;
uniform float lens_radius : hint_range(0.01, 0.2) = 0.090;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
}

void fragment() {
	// Clip strictly to circular lens aperture so lid never leaves the lens
	if (length(local_pos.xz) > lens_radius) {
		discard;
	}
	
	// Curved lower eyelid edge in mesh-local space (local -Z is UP, +Z is DOWN)
	float x = clamp(local_pos.x / lens_radius, -1.0, 1.0);
	float edge = mix(-lens_radius - curve, lens_radius + curve, coverage)
	           + curve * (1.0 - x * x) * (1.0 - coverage);
	
	// Only upper part (above edge towards -Z) is lid
	if (local_pos.z > edge) {
		discard;
	}
	
	ALBEDO = albedo_color.rgb;
	ROUGHNESS = roughness;
	METALLIC = 0.02;
}
