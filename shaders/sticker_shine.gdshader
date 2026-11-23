shader_type canvas_item;

uniform float shine_pos : hint_range(-0.5, 1.5) = -0.4;
uniform float shine_width : hint_range(0.02, 0.4) = 0.14;
uniform float shine_intensity : hint_range(0.0, 1.0) = 0.35;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float diag = UV.x * 0.82 + UV.y * 0.25;
	float dist = abs(diag - shine_pos);
	float band = smoothstep(shine_width, 0.0, dist);
	vec3 lit = tex.rgb + vec3(1.0, 0.99, 0.94) * (band * shine_intensity * tex.a);
	COLOR = vec4(lit, tex.a) * COLOR;
}
