// TV Dynamic picture mode (anime-shader project, 2026-11-18). Runs after the line shader.
// Like a TV's "Dynamic" preset, but without clipping:
//  - gentle S-curve on brightness (deeper shadows, brighter highlights, no crushed black or blown white)
//  - vibrance: boosts dull colours more than already-strong ones, so skin and saturated paint don't clip
//  - slightly cool white point, as TV dynamic modes use
// One pass, per pixel, no neighbourhood reads.

//!PARAM tv_contrast
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.0
0.30

//!PARAM tv_vibrance
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 1.5
0.45

//!PARAM tv_cool
//!TYPE float
//!MINIMUM 0.0
//!MAXIMUM 0.1
0.025

//!HOOK MAIN
//!BIND HOOKED
//!DESC TV Dynamic picture mode

vec4 hook() {
    vec4 c = HOOKED_tex(HOOKED_pos);
    vec3 rgb = clamp(c.rgb, 0.0, 1.0);
    const vec3 W = vec3(0.2126, 0.7152, 0.0722);
    float y = dot(rgb, W);
    // S-curve around mid-grey; slope at 0 and 1 stays 1 - tv_contrast > 0, so black and white keep their detail
    float s = y * y * (3.0 - 2.0 * y);
    float y2 = mix(y, s, tv_contrast);
    // vibrance: gain shrinks as the pixel's own saturation grows
    float sat = max(rgb.r, max(rgb.g, rgb.b)) - min(rgb.r, min(rgb.g, rgb.b));
    float gain = 1.0 + tv_vibrance * (1.0 - sat) * (1.0 - sat);
    vec3 col = (rgb - y) * gain;
    // keep the boosted colour inside 0..1 by limiting the gain where it would clip
    vec3 o = y2 + col;
    float hi = max(o.r, max(o.g, o.b)), lo = min(o.r, min(o.g, o.b));
    float k = 1.0;
    if (hi > 1.0) k = min(k, (1.0 - y2) / max(hi - y2, 1e-4));
    if (lo < 0.0) k = min(k, y2 / max(y2 - lo, 1e-4));
    o = y2 + col * k;
    // slightly cool white point, scaled by brightness so blacks stay neutral
    o *= vec3(1.0 - tv_cool * y2, 1.0, 1.0 + tv_cool * y2);
    return vec4(clamp(o, 0.0, 1.0), c.a);
}
