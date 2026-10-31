shader_type canvas_item;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float brightness = max(source.r, max(source.g, source.b));
	// Remap the warm palette to blue while preserving shading and transparency.
	vec3 blue = mix(vec3(0.015, 0.08, 0.48), vec3(0.16, 0.65, 1.0), brightness);
	COLOR = vec4(blue, source.a);
}
