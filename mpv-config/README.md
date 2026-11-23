# mpv configuration

This is my personal mpv setup. See the main README for installation, dependencies and controls. It contains preferences for Intel hardware decoding, PipeWire, a 60 Hz touchscreen and Japanese audio; edit `mpv.conf` for your system. Pan smoothing needs VapourSynth, MVTools and NumPy. The audio impulse responses are supplied separately by the user.

## Third-party components

- [Anime4K](https://github.com/bloc97/Anime4K), MIT; its notices are in the shader files.
- [uosc](https://github.com/tomasklaen/uosc), LGPL; see `licenses/uosc-LGPL.txt`. The Timeline script has been changed to hide thumbnails beyond the furthest point reached in the current video.
- [thumbfast](https://github.com/po5/thumbfast), MPL-2.0; see `licenses/thumbfast-MPL-2.0.txt`.
- mpv's autoload script, GPL; see `licenses/mpv-GPL.txt` and [mpv](https://github.com/mpv-player/mpv).

The uosc helper binaries are omitted. Custom scripts and settings are included without watch history, personal paths, or audio impulse responses.
