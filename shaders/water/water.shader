shader_type canvas_item;

uniform sampler2D our_texture: hint_albedo;
uniform float tile_factor = 10.0;
uniform vec2 time_factor = vec2(2.0, 3.0);
uniform vec2 offset_factor = vec2(5.0, 2.0);
uniform vec2 amplitude = vec2(0.05, 0.05);

void fragment() {
	vec2 adjusted_uv = UV * tile_factor;
	adjusted_uv.y *= SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y;
	
	vec2 offset = vec2(sin(TIME * time_factor.x + (adjusted_uv.x + adjusted_uv.y) * offset_factor.x) * amplitude.x, cos(TIME * time_factor.y + (adjusted_uv.x + adjusted_uv.y) * offset_factor.y) * amplitude.y);
	adjusted_uv.x += offset.x;
	adjusted_uv.y += offset.y;
	
	COLOR = texture(our_texture, adjusted_uv);
	
	vec3 tangent = normalize(vec3(amplitude.x, 0.0, -offset.x));
	vec3 bitangent = normalize(vec3(0.0, amplitude.y, -offset.y));
	
	NORMAL = normalize(cross(tangent, bitangent));
}