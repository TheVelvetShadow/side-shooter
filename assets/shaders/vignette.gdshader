shader_type canvas_item;

// Strength of the vignette — higher = darker edges. Tweak in inspector.
uniform float strength : hint_range(0.0, 3.0) = 1.2;
// Alpha of the full black overlay at screen corners
uniform float opacity : hint_range(0.0, 1.0) = 0.85;

void fragment() {
	// Remap UV to -1..+1 centred on screen
	vec2 uv = UV * 2.0 - 1.0;
	// Radial distance, squished slightly so corners are heavier than edges
	float dist = dot(uv * vec2(0.75, 1.0) * strength, uv * vec2(0.75, 1.0) * strength);
	// Smooth curve — pow gives a sharper falloff than linear
	float vignette = clamp(1.0 - dist, 0.0, 1.0);
	vignette = pow(vignette, 2.2);
	// Output: black with alpha = 1 at edges, 0 at centre
	COLOR = vec4(0.0, 0.0, 0.0, (1.0 - vignette) * opacity);
}
