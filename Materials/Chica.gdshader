shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D diffuse_texture;
uniform sampler2D normal_map: hint_normal;
uniform float normal_scale : hint_range(-16.0, 16.0);
uniform sampler2D mask_map;
uniform sampler2D paint_map;

uniform vec3 paint_color_r : source_color;
uniform vec3 paint_color_g: source_color;
uniform vec3 paint_color_b: source_color;
uniform vec3 paint_color_a: source_color;



void fragment() {
    vec2 uv = UV;

    vec4 base_color = texture(diffuse_texture, uv);
    vec4 paint = texture(paint_map, uv);
    vec4 masks = texture(mask_map, uv);

    // Mix base with paint colors by channels
    vec3 paint_result = base_color.rgb;
    paint_result = mix(paint_result, paint_color_r, paint.r);
    paint_result = mix(paint_result, paint_color_g, paint.g);
    paint_result = mix(paint_result, paint_color_b, paint.b);
    paint_result = mix(paint_result, paint_color_a, paint.a);

    ALBEDO = paint_result;

    EMISSION = paint_result * masks.b;
    ROUGHNESS = masks.g;
    METALLIC = masks.r;

	NORMAL_MAP = texture(normal_map, uv).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
}
