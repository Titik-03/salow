# mpv configuration

This is my personal mpv setup. See the main README for installation, dependencies and controls. It uses automatic graphics, hardware decoding and audio output, with preferences for a 60 Hz display and Japanese audio. Pan smoothing needs VapourSynth, MVTools and NumPy. The X-Fi and Atmos audio impulse responses are included and installed automatically.

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

The full installer copies `irs/xfi-crystalizer.wav` and `irs/dolby-atmos.wav` into your mpv configuration. Alt+3 cycles Original / Atmos / X-Fi. These are impulse-response effects, not Dolby or Creative drivers. A missing response falls back to original sound. Existing custom responses and saved choices are preserved, with the previous configuration backed up.

On Ubuntu / Debian, install the playback packages, then run the full installer from the Salow folder:

```sh
sudo apt update
sudo apt install mpv ffmpeg git
./install-config.sh
```

On other Linux distributions, install `mpv` and `ffmpeg` through your package manager, then run the same installer as your normal user. Restart mpv afterward.

Pan smoothing needs an mpv build with VapourSynth, plus MVTools and NumPy. Alt+2 reports unavailable when mpv cannot add the filter; the remaining controls keep working. The uosc helper binaries are omitted, so clipboard and subtitle-download features are unavailable.

## Third-party components

- [Anime4K](https://github.com/bloc97/Anime4K), MIT; its notices are in the shader files.
- [uosc](https://github.com/tomasklaen/uosc), LGPL; see `licenses/uosc-LGPL.txt`. The Timeline script has been changed to hide thumbnails beyond the furthest point reached in the current video.
- [thumbfast](https://github.com/po5/thumbfast), MPL-2.0; see `licenses/thumbfast-MPL-2.0.txt`.
- mpv's autoload script, GPL; see `licenses/mpv-GPL.txt` and [mpv](https://github.com/mpv-player/mpv).

The uosc helper binaries are omitted. Custom scripts and settings are included without watch history or personal paths.
