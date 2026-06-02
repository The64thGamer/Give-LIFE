shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 3.0;

void fragment() {
    vec2 pixel = blur_amount / vec2(textureSize(TEXTURE, 0));

    vec4 color = vec4(0.0);
    float total = 0.0;

    for (int x = -6; x <= 6; x++) {
        for (int y = -6; y <= 6; y++) {
            float weight = exp(-float(x*x + y*y) / (2.0 * 9.0));
            color += texture(TEXTURE, UV + vec2(float(x), float(y)) * pixel) * weight;
            total += weight;
        }
    }

    vec4 blurred = color / total;
    COLOR = blurred * COLOR.a;  // apply only the modulate alpha, not the texture
}