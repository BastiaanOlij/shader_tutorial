shader_type canvas_item;

uniform float tile_factor = 10.0;
uniform float aspect_ratio = 0.5;

uniform sampler2D DuDvMap : hint_black;
uniform vec2 time_factor = vec2(0.05, 0.08);
uniform vec2 DuDvFactor = vec2(0.2, 0.2);
uniform float DuDvAmplitude = 0.1;

void fragment() {
	vec2 DuDv_UV = UV * DuDvFactor; // Determine the UV that we use to look up our DuDv
	DuDv_UV += TIME * time_factor; // add some animation
	
	vec2 offset = texture(DuDvMap, DuDv_UV).rg; // Get our offset
	offset = offset * 2.0 - 1.0; // Convert from 0.0 <=> 1.0 to -1.0 <=> 1.0
	offset *= DuDvAmplitude; // And apply our amplitude
	
	vec2 adjusted_uv = UV * tile_factor; // Determine the UV for our texture lookup
	adjusted_uv.y *= aspect_ratio; // Apply aspect ratio
	adjusted_uv += offset; // Distort using our DuDv offset
	
	COLOR = texture(TEXTURE, adjusted_uv); // And lookup our color
	NORMALMAP = texture(NORMAL_TEXTURE, DuDv_UV).rgb;
}