shader_type canvas_item;

uniform float tile_factor = 10.0;
uniform float aspect_ratio = 0.5;

uniform vec2 time_factor = vec2(2.0, 3.0);
uniform vec2 offset_factor = vec2(5.0, 2.0);
uniform vec2 amplitude = vec2(0.05, 0.05);

void fragment() {
	vec2 adjusted_uv = UV * tile_factor;
	adjusted_uv.y *= aspect_ratio;
	
	adjusted_uv.x += sin(TIME * time_factor.x + (adjusted_uv.x + adjusted_uv.y) * offset_factor.x) * amplitude.x;
	adjusted_uv.y += cos(TIME * time_factor.y + (adjusted_uv.x + adjusted_uv.y) * offset_factor.y) * amplitude.y;
	
	COLOR = texture(TEXTURE, adjusted_uv);
}