shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 6.0) = 3.2;
uniform float tint_alpha : hint_range(0.0, 0.7) = 0.14;
uniform vec4 tint_color : source_color = vec4(0.08, 0.20, 0.45, 1.0);

void fragment() {
	vec2 ps = SCREEN_PIXEL_SIZE;
	vec4 col = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur_amount);
	// Additional smooth multi-ring sample for velvety bokeh blur
	if (blur_amount > 0.05) {
		float r = blur_amount * 2.2;
		vec4 acc = col * 0.28;
		acc += textureLod(SCREEN_TEXTURE, SCREEN_UV + vec2(r, 0.0) * ps, blur_amount * 0.8) * 0.12;
		acc += textureLod(SCREEN_TEXTURE, SCREEN_UV + vec2(-r, 0.0) * ps, blur_amount * 0.8) * 0.12;
		acc += textureLod(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, r) * ps, blur_amount * 0.8) * 0.12;
		acc += textureLod(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, -r) * ps, blur_amount * 0.8) * 0.12;
		acc += textureLod(SCREEN_TEXTURE, SCREEN_UV + vec2(r * 0.7, r * 0.7) * ps, blur_amount * 0.8) * 0.06;
		acc += textureLod(SCREEN_TEXTURE, SCREEN_UV + vec2(-r * 0.7, r * 0.7) * ps, blur_amount * 0.8) * 0.06;
		acc += textureLod(SCREEN_TEXTURE, SCREEN_UV + vec2(r * 0.7, -r * 0.7) * ps, blur_amount * 0.8) * 0.06;
		acc += textureLod(SCREEN_TEXTURE, SCREEN_UV + vec2(-r * 0.7, -r * 0.7) * ps, blur_amount * 0.8) * 0.06;
		col = acc;
	}
	float k = clamp(blur_amount / 3.5, 0.0, 1.0);
	COLOR = mix(col, vec4(tint_color.rgb, 1.0), tint_alpha * k);
	COLOR.a = 1.0;
}
