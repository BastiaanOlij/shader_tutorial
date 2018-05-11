shader_type canvas_item;

uniform vec2 time_factor = vec2(2.0, 2.0);
uniform vec2 amplitude = vec2(10.0, 10.0);

void vertex() {
	VERTEX.x += sin(TIME * time_factor.x + VERTEX.x + VERTEX.y) * amplitude.x;
	VERTEX.y += cos(TIME * time_factor.y + VERTEX.x + VERTEX.y) * amplitude.y;
}