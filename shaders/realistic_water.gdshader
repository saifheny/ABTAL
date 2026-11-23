shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, specular_schlick_ggx;

uniform vec4 shallow_color : source_color = vec4(0.03, 0.54, 0.72, 0.86);
uniform vec4 deep_color : source_color = vec4(0.01, 0.20, 0.45, 0.95);
uniform vec4 sky_reflect_color : source_color = vec4(0.45, 0.78, 0.96, 1.0);
uniform float wave_speed : hint_range(0.1, 4.0) = 1.25;
uniform float wave_height : hint_range(0.0, 0.35) = 0.08;

varying vec3 v_world_pos;

float wave_fn(vec2 p, float t) {
	float w1 = sin(p.x * 1.15 + p.y * 0.45 + t * 1.9);
	float w2 = cos(p.y * 1.45 - p.x * 0.35 - t * 1.5);
	float w3 = sin((p.x * 0.7 - p.y * 1.3) * 1.85 + t * 2.4) * 0.45;
	return (w1 + w2 + w3) * 0.32;
}

float caustic_net(vec2 p, float t) {
	vec2 a = p * 1.65 + vec2(t * 0.42, -t * 0.31);
	vec2 b = vec2(p.x * 1.1 - p.y * 1.3, p.x * 1.2 + p.y * 0.9) * 1.4 + vec2(-t * 0.28, t * 0.37);
	float ridge1 = 1.0 - abs(sin(a.x + sin(a.y * 1.3) * 0.7));
	float ridge2 = 1.0 - abs(cos(b.y + cos(b.x * 1.2) * 0.7));
	return pow(clamp(ridge1 * ridge2, 0.0, 1.0), 4.5);
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float h = wave_fn(wp.xz, TIME * wave_speed) * wave_height;
	VERTEX.y += h;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float t = TIME * wave_speed;
	vec2 p = v_world_pos.xz;

	// Analytical multi-directional water surface normal for crisp sunlit sky ripples
	float eps = 0.09;
	float h0 = wave_fn(p, t) + wave_fn(p * 2.7 + vec2(3.1, -1.7), -t * 1.35) * 0.32;
	float hx = wave_fn(p + vec2(eps, 0.0), t) + wave_fn((p + vec2(eps, 0.0)) * 2.7 + vec2(3.1, -1.7), -t * 1.35) * 0.32;
	float hz = wave_fn(p + vec2(0.0, eps), t) + wave_fn((p + vec2(0.0, eps)) * 2.7 + vec2(3.1, -1.7), -t * 1.35) * 0.32;
	vec3 n_wave = normalize(vec3((h0 - hx) * 1.25, 1.0, (h0 - hz) * 1.25));
	vec3 n_view = normalize((VIEW_MATRIX * vec4(n_wave, 0.0)).xyz);

	vec3 view_dir = normalize(VIEW);
	float fresnel = pow(1.0 - clamp(dot(n_view, view_dir), 0.0, 1.0), 3.8);

	vec3 base_col = mix(deep_color.rgb, shallow_color.rgb, clamp(h0 * 0.45 + 0.50, 0.0, 1.0));
	float caustics = caustic_net(p * 0.55, t) * 0.24 + caustic_net(p * 1.15, -t * 0.8) * 0.14;
	vec3 water_col = base_col + vec3(0.18, 0.46, 0.58) * caustics;

	vec3 final_col = mix(water_col, sky_reflect_color.rgb, clamp(fresnel * 0.62, 0.0, 0.72));

	ALBEDO = final_col;
	NORMAL = n_view;
	ROUGHNESS = 0.06;
	METALLIC = 0.18;
	SPECULAR = 0.90;
	ALPHA = mix(shallow_color.a, deep_color.a, clamp(0.65 + fresnel * 0.35, 0.0, 1.0));
}
