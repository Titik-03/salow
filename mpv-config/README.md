# mpv configuration

This is my personal mpv setup. See the main README for installation, dependencies and controls. It contains preferences for Intel hardware decoding, PipeWire, a 60 Hz touchscreen and Japanese audio; edit `mpv.conf` for your system. Pan smoothing needs VapourSynth, MVTools and NumPy. The audio impulse responses are supplied separately by the user.

## Controls

| Key | Action |
|---|---|
| Ctrl+1 | Salow + TV Dynamic |
| Ctrl+2 | Anime4K A+A + TV Dynamic |
| Ctrl+0 | Shaders off |
| Ctrl+3 / Ctrl+5 | Natural look / TV Dynamic |
| Alt+1 | Toggle frame mixing |
| Alt+2 | Toggle pan smoothing (off at startup) |
| Alt+A | Cycle available audio effects |
| Tab / Shift+Tab | Skip forward / back 85 seconds |

## Audio and optional components

Audio starts native unless you supply `irs/xfi-crystalizer.wav`, which selects X-Fi at startup. The optional `irs/dolby-atmos.wav` and `irs/razor-surround.wav` enable those modes. Impulse responses are not bundled because their redistribution terms are unestablished. The current audio script does not escape special characters in the impulse-response path; use a configuration path without quotes, commas, colons or brackets.

Pan smoothing needs an mpv build with VapourSynth, plus MVTools and NumPy; leave it off if these are unavailable. The uosc helper binaries are omitted, so clipboard and subtitle-download features are unavailable.

## Third-party components

- [Anime4K](https://github.com/bloc97/Anime4K), MIT; its notices are in the shader files.
- [uosc](https://github.com/tomasklaen/uosc), LGPL; see `licenses/uosc-LGPL.txt`. The Timeline script has been changed to hide thumbnails beyond the furthest point reached in the current video.
- [thumbfast](https://github.com/po5/thumbfast), MPL-2.0; see `licenses/thumbfast-MPL-2.0.txt`.
- mpv's autoload script, GPL; see `licenses/mpv-GPL.txt` and [mpv](https://github.com/mpv-player/mpv).

The uosc helper binaries are omitted. Custom scripts and settings are included without watch history, personal paths, or audio impulse responses.
