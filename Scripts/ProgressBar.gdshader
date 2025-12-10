shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0; // how filled the circle is
uniform vec4 bar_color : source_color = vec4(0.2, 1.0, 0.2, 1.0); // progress color
uniform vec4 back_color : source_color = vec4(0.3, 0.3, 0.3, 1.0); // background track
uniform vec4 border_color : source_color = vec4(0.0, 0.0, 0.0, 1.0); // border color
uniform float radius = 0.45; // max radius of ring (smaller = fits inside box)
uniform float thickness = 0.08; // thickness of the ring
uniform float border_size = 0.02; // border thickness

void fragment() {
    vec2 center = UV - vec2(0.5);
    float r = length(center);

    // angle normalized [0,1]
    float angle = atan(center.y, center.x) / (2.0 * 3.14159265) + 0.5;

    // main ring cutoff
    float outer_cut = step(r, radius);
    float inner_cut = step(radius - thickness, r);
    float ring = outer_cut * inner_cut;

    // border ring
    float outer_border_cut = step(r, radius + border_size);
    float inner_border_cut = step(radius - thickness - border_size, r);
    float border_ring = outer_border_cut * inner_border_cut - ring;

    // progress cutoff
    float filled = step(angle, progress);

    if (border_ring > 0.5) {
        COLOR = border_color;
    } else if (ring > 0.5) {
        if (filled > 0.5) {
            COLOR = bar_color;
        } else {
            COLOR = back_color;
        }
    } else {
        COLOR = vec4(0.0, 0.0, 0.0, 0.0);
    }
}
