shader_type canvas_item;
varying vec4 tint;
void vertex() { tint = COLOR; }
void fragment() {
    vec4 source = texture(TEXTURE, UV);
    float brightness = max(source.r, max(source.g, source.b));
    COLOR = vec4(tint.rgb * (0.55 + 0.45 * brightness), source.a * tint.a);
}
