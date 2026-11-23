# mpv configuration

This is my personal mpv setup. See the main README for installation, dependencies and controls. It contains preferences for Intel hardware decoding, PipeWire, a 60 Hz touchscreen and Japanese audio; edit `mpv.conf` for your system. Pan smoothing needs VapourSynth, MVTools and NumPy. The audio impulse responses are supplied separately by the user.

## Controls

| Key | Action |
|---|---|
| Ctrl+1 | Salow (startup model; preserves selected look) |
| Ctrl+2 | Salow Medium (preserves selected look) |
| Ctrl+0 | Shaders off |
| Ctrl+3 | Toggle natural / TV Dynamic |
| Alt+1 | Toggle frame mixing (remembered, initially off) |
| Alt+2 | Toggle pan smoothing (remembered, initially off) |
| Alt+3 | Original / Atmos / X-Fi (remembered, initially X-Fi) |
| Tab / Shift+Tab | Skip forward / back 85 seconds |

## Audio and optional components

Shader selection starts with Salow + TV Dynamic each launch. Ctrl+0 disables both shaders; Ctrl+3 changes the look without enabling a disabled shader. Motion and audio choices are saved in `salow-state.json` inside the mpv configuration folder, including the off/original choice.

Supply `irs/xfi-crystalizer.wav` and `irs/dolby-atmos.wav` for the X-Fi and Atmos modes. A missing impulse response falls back to original sound. Impulse responses are not bundled because their redistribution terms are unestablished. The installer retains your supplied responses and saved choices, and backs up the entire previous configuration before replacement.

Pan smoothing needs an mpv build with VapourSynth, plus MVTools and NumPy; leave it off if these are unavailable. The uosc helper binaries are omitted, so clipboard and subtitle-download features are unavailable.

## Third-party components

- [Anime4K](https://github.com/bloc97/Anime4K), MIT; its notices are in the shader files.
- [uosc](https://github.com/tomasklaen/uosc), LGPL; see `licenses/uosc-LGPL.txt`. The Timeline script has been changed to hide thumbnails beyond the furthest point reached in the current video.
- [thumbfast](https://github.com/po5/thumbfast), MPL-2.0; see `licenses/thumbfast-MPL-2.0.txt`.
- mpv's autoload script, GPL; see `licenses/mpv-GPL.txt` and [mpv](https://github.com/mpv-player/mpv).

The uosc helper binaries are omitted. Custom scripts and settings are included without watch history, personal paths, or audio impulse responses.
