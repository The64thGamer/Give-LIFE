shader_type canvas_item;

uniform vec2 uv_offset = vec2(0.0, 0.0); // Offset for X and Y
uniform vec2 uv_scale = vec2(1.0, 1.0);  // Scale for X and Y

void fragment() {
    // Modify the UVs based on the parameters
    vec2 modified_uv = UV * uv_scale + uv_offset;
    COLOR = texture(TEXTURE, modified_uv);
}
