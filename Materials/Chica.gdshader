shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D diffuse_texture;
uniform sampler2D normal_map : hint_normal;
uniform float normal_scale : hint_range(-16.0, 16.0);
uniform sampler2D mask_map;
uniform sampler2D paint_map : hint_default_transparent;
uniform sampler2D blacklight_map : hint_default_black;

uniform vec3 paint_color_r : source_color;
uniform vec3 paint_color_g : source_color;
uniform vec3 paint_color_b : source_color;
uniform vec3 paint_color_a : source_color;

// Declare blacklight color as uniform (default to #6c5cd9)
uniform vec3 blacklight_color = vec3(0.496, 0.36, 0.785);

void fragment() {
    vec2 uv = UV;

    vec4 base_color = texture(diffuse_texture, uv);
    vec4 paint = texture(paint_map, uv);
    vec4 masks = texture(mask_map, uv);

    vec3 paint_result = base_color.rgb;
    paint_result = mix(paint_result, paint_color_r, paint.r);
    paint_result = mix(paint_result, paint_color_g, paint.g);
    paint_result = mix(paint_result, paint_color_b, paint.b);
    paint_result = mix(paint_result, paint_color_a, paint.a);

    ALBEDO = paint_result;

    ROUGHNESS = masks.g;
    METALLIC = masks.r;

    NORMAL_MAP = texture(normal_map, uv).rgb;
    NORMAL_MAP_DEPTH = normal_scale;
}


float DistributionGGX(float cos_theta_m, float alpha)
{
	float alpha2 = alpha * alpha;
	float d = 1.0 + (alpha2 - 1.0) * cos_theta_m * cos_theta_m;
	return alpha2 / (PI * d * d);
}

float GeometryGGX(float NdotL, float NdotV, float alpha)
{
	return 0.5 / mix(2.0 * NdotL * NdotV, NdotL + NdotV, alpha);
}

vec3 SchlickBaseReflectivity(float metallic, float specular, vec3 albedo)
{
	float dielectric = 0.04 * specular * specular;
	return mix(vec3(dielectric), albedo, vec3(metallic));
}

float SchlickFresnel(float u)
{
	float m = 1.0 - u;
	float m2 = m * m;
	return m2 * m2 * m;
}

void light()
{
	// Calculate some vectors.
	vec3 lightColor = LIGHT_COLOR / PI;

	vec3 half = normalize(VIEW + LIGHT);

	float NdotL = max(dot(NORMAL, LIGHT), 0.0);
	float NdotV = max(dot(NORMAL, VIEW), 0.0);
	float NdotH = max(dot(NORMAL, half), 0.0);
	float LdotH = max(dot(LIGHT, half), 0.0);

	// Diffuse light (Lambert).
	DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * lightColor;

	// Specular light (Schlick-GGX).
	float ggxAlpha = ROUGHNESS * ROUGHNESS;
	float D = DistributionGGX(NdotH, ggxAlpha);
	float G = GeometryGGX(NdotL, NdotV, ggxAlpha);

	vec3 f0 = SchlickBaseReflectivity(METALLIC, SPECULAR_AMOUNT, ALBEDO);
	float LdotH5 = SchlickFresnel(LdotH);
	float f90 = clamp(50.0 * f0.g, 0.0, 1.0);
	vec3 F = f0 + (f90 - f0) * LdotH5;

	vec3 specularBRDF = max(NdotL * D * G * F, 0.0);
	SPECULAR_LIGHT += specularBRDF * LIGHT_COLOR * ATTENUATION;
    // Blacklight check
	float match = float(distance(normalize(LIGHT_COLOR.rgb), normalize(blacklight_color)) < 0.05);

    // Load blacklight emission map
	SPECULAR_LIGHT += pow(texture(blacklight_map, UV).rgb, vec3(2.2)) * match * ATTENUATION * NdotL * length(LIGHT_COLOR) * 10.0;
}
