# Technical details

[Back to Salow](../README.md)

### Line detail and similarity to Anime4K A+A

Measured on 4 held-out clips (bright, dark, close-up face, busy detail), 12 frames each. Lower is closer to A+A.

| | Salow | Salow Medium |
|---|---|---|
| Mean difference from A+A (0–255 code values), face / dark clip | 0.29 / 0.32 | 0.38 / 0.39 |
| Mean difference on edges, face / bright clip | 4.1 / 4.0 | 5.7 / 5.9 |
| Thin-line depth (A+A: 14.8 face, 12.6 bright) | 16.6 / 13.7 | 15.9 / 12.7 |

In these samples, Medium is less close to A+A on fine edges. Line depth is not an error score: the target varies by clip, and a higher number means a darker line, not necessarily a better result. Choose the version that works best on your system.

A separate offscreen test measured line shimmer and thin-line depth in five held-out 48-frame clips on the same Intel GPU. The current Salow was called **Salow Steady** in those notes; the earlier Salow is the version without its thin-line and temporal steps:

| Measurement | Anime4K A+A | Earlier Salow | Current Salow |
|---|---:|---:|---:|
| Still clip: edge shimmer (code values; lower is less frame-to-frame change) | 0.468 | 0.533 | 0.350 |
| Dark clip: edge shimmer (code values; lower is less) | 0.603 | 0.607 | 0.463 |
| Dark clip: thin-line depth (code values; higher is darker) | 10.58 | 7.31 | 9.83 |

These differences were measured on selected areas and clips. The shimmer changes are small, and visibility was not established. The underlying captures and runner were removed during project cleanup, so these figures are retained from the original test notes; the screenshots above are new examples, not those original test captures. See [comparison notes](comparison-notes.md).

## TV Dynamic

TV Dynamic is the picture look I pair with Salow. Its single pass applies an S-curve to brightness, gives less-saturated colours a stronger vibrance boost, and adds a slightly cool white point. It can also be used without Salow. The shader limits colour gain and clamps its output, but the look changes colour and contrast by design; it is not a calibrated display profile. The visual effect and cost have not been separately measured in the timing comparison above.

## Pan smoothing

Pan smoothing is part of the optional [mpv configuration](../mpv-config/), not a shader. It estimates motion at reduced resolution and uses VapourSynth MVTools interpolation when the motion resembles a camera pan. Other scenes use a frame-mixing path. For approximately 23.976 or 24 fps sources it outputs approximately 59.94 or 60 fps; 25 fps becomes 62.5 fps. Other source frame rates pass through without this processing.

It is **off by default** and toggled with **Alt+2** in the configuration package. It requires an mpv build with VapourSynth, VapourSynth MVTools and NumPy. It can increase CPU and GPU work, and motion estimation can produce artifacts. Its compatibility and performance depend on the installed versions, hardware and video; no universal smoothness or timing claim is implied.


### Tuning TV Dynamic

The look has three parameters you can set in `mpv.conf`, for example:

```ini
glsl-shader-opts=tv_contrast=0.30,tv_vibrance=0.45,tv_cool=0.025
```

| Parameter | Range | Default | Effect |
|---|---|---|---|
| `tv_contrast` | 0–1 | 0.30 | S-curve strength (deeper shadows, brighter highlights) |
| `tv_vibrance` | 0–1.5 | 0.45 | Boosts dull colours more than already-strong ones |
| `tv_cool` | 0–0.1 | 0.025 | Cooler white point, scaled by brightness so blacks stay neutral |

## How it works

Salow is a small convolutional network (3×3 convolutions with 4 channels, CReLU), trained to reproduce Anime4K A+A's
output at native 1080p. It uses Anime4K's layer layout and starting weights and is fine-tuned on anime frames with
A+A as the teacher. The last layer is made 10% stronger for slightly crisper lines. A+A's de-ringing step
(Clamp_Highlights) is folded into the last pass, which saves two passes.

After the network, the last pass also:

1. **Thin-line depth:** finds thin dark ridges with a local maximum below about 150/255 and adds a bounded darkening correction. In one tested clip the result exceeded A+A's measured depth.
2. **Steady:** keeps the previous frame's correction in a storage texture. Where both the source pixel and the
   correction changed by less than about 1–3 code values, it averages the two (60% weight at most). The gate is intended to leave moving areas alone.

Things we tried that did **not** make Salow faster without changing its output, on this Intel iGPU:
half precision (`mediump`, ignored by the driver), reading textures with `texelFetch`, sharing the 5×5
neighbourhood reads, and compute-shader versions of the passes.

