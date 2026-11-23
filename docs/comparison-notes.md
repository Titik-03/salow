# Salow Steady: results (2026-11-19; installed as Salow at the user's request the same day)

Build: SHA-256 d231f83bcecf, the current `shaders/salow.hook`. The earlier Salow build had SHA-256 prefix 20e0ed0977ca. These are historical notes; the captures and test runner are not included.

## What A+A cannot do, and Salow Steady does
1. **Memory between frames.** libplacebo keeps a `//!TEXTURE ... //!STORAGE` texture from frame to frame. Test: each output frame equalled the previous input exactly (mean difference 0.00). So the shader can remember the last frame. A+A is frame-by-frame.
2. **Thin dark lines in dim areas at A+A's depth.** Salow drew them lighter there, and that is the blur the user felt.

## Test setup
- Headless libplacebo 7.360 runner (C, Vulkan, Intel MTL iGPU, power-saver) with 5 held-out Clannad AS ep 18 clips of 48 frames each: still 372 s, dark 322 s, slow 264 s, mid 302 s, pan 470 s.
- FFmpeg's libplacebo filter would not initialise on this system, even with no shader.
- The runner lived in the session scratch folder and is not kept.

## Thin-line depth (source minus output on thin dark ridges, code values; higher = darker line)

| Clip | A+A | Salow | Salow Steady |
|---|---|---|---|
| dark | 10.58 | 7.31 | **9.83** |
| still | 15.86 | 14.13 | 14.83 |
| mid | 18.95 | 17.79 | 18.19 |
| pan | 18.82 | 17.58 | 17.84 |
| slow | 17.02 | 17.47 | 17.86 |

- **By brightness band** of the line's bright side, where Salow was short: 40–60: A+A 4.0, Salow 1.5. 60–80: 6.2 vs 3.9. 80–100: 7.1 vs 5.3. Above 140 Salow already matched A+A and is not changed.
- **Settings:** the boost uses strength 0.19 and fades out at 150 so that it stays at or under A+A per band. Stronger settings (0.21/165, 0.25/140) overshot A+A by up to 0.5–0.7 in the 60–100 bands.
- **Slow clip:** Salow was already 0.45 darker than A+A here, and Steady adds 0.39. This is the one clip where it exceeds A+A (+0.84).
- **Elsewhere:** edge steepness is unchanged (all clips within 0.05). No pixel changed by more than 4 code values against Salow.

## Shimmer (frame-to-frame change on line edges where the source changed only by codec noise, code values)

| Clip | source | A+A | Salow | Salow Steady |
|---|---|---|---|---|
| still | 0.200 | 0.468 | 0.533 | **0.350** |
| dark | 0.315 | 0.603 | 0.607 | **0.463** |
| slow | 0.288 | 0.640 | 0.697 | **0.507** |
| mid | 1.092 | 1.684 | 1.703 | **1.599** |

- **Motion:** moving areas differ from Salow by 0.01–0.14 on average (pan 0.011). The 99.9th percentile is the same as without steadying, which does not rule out ghosting in other footage.
- **Cost:** pixel-identical source frames now change by an extra 0.005–0.01 code values in flat areas while the average settles.
- **Honest limit:** these shimmer levels are small. 81% of pixels in still shots are exactly identical frame to frame, and Salow and A+A never flicker there. Whether the change is visible is for the user's viewing to decide.

## Cost (the changed last pass relative to the three unchanged passes, same frames; totals vary ±1.5 ms run to run on power-saver)

| Build | Ratio |
|---|---|
| Salow | 0.53 |
| + thin lines | 0.59–0.63 |
| + steady, fragment pass (shipped) | 0.63–0.66 |
| + steady as a compute pass (rejected, slower) | 0.73–0.84 |

Estimated about +0.4–0.5 ms on Salow's ~7 ms in real mpv. This is an estimate, not measured in mpv.

## Not done
- **Real mpv playback:** not run by the agent (desktop rule). Your mpv uses vo=gpu-next with Vulkan, which is the same libplacebo path as the runner. The OpenGL fallback is untested.
- **Window-bar rim fix:** not attempted in this round.

## Live mpv cost (user's config, gpu-next/Vulkan, interpolation, power-saver, Clannad from 4:24, 20 s after 5 s warm-up, 2 runs each, alternating order)

| Build (with TV dynamic) | GPU ms/frame (mpv vo-passes) | Drops |
|---|---|---|
| no shader (no TV dynamic) | 2.01 / 1.94 | 0 |
| Salow | 9.06 / 8.98 | 0 |
| Salow Steady | 9.31 / 9.46 | 0 |
| A+A | 23.99 / 22.41 | 0 |

No shader errors in the logs.
