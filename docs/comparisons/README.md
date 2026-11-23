# Image comparison details

These examples use one source frame per show, rendered in four separate runs. The full-frame images are lossless WebP copies of 1920×1080 RGB renders. The detail boards use the same 700×440-pixel crop for all four arms without scaling; the full-scene boards use identically resized views. Subtitles and the watermark visible in some full frames were already burned into the sources.

- **Clannad: After Story**, episode 18: seek to 430 seconds, process 25 decoded frames and capture frame index 24; crop `(610, 260)` to `(1310, 700)`.
- **The Apothecary Diaries**, episode 1: seek to 360 seconds, process 25 decoded frames and capture frame index 24; crop `(1190, 150)` to `(1890, 590)`.
- Both sources: 1920×1080, yuv420p, 24000/1001 fps; source colour metadata was unspecified for Clannad. The same FFmpeg defaults were used for each arm.
- FFmpeg n9.0.2 and libplacebo v7.387.0 via Vulkan on Intel Graphics (MTL); offscreen, without subtitles added by the player. All four arms use the same 1920×1080 output and conversion settings.
- Original uses no custom shader. Anime4K A+A uses the seven files in `mpv-config/shaders/` in the same order as the A+A binding in `mpv-config/input.conf`. Salow uses the full `shaders/salow.hook`. Salow + TV Dynamic appends `shaders/tv-dynamic.glsl` with default parameters. No pan smoothing was used.
- SHA-256 of Salow: `d231f83bcecf259e185fb727cff104ffe9b0980ff8c868244c995cb192768b91`; TV Dynamic: `2aa6c45cc027d85bcf5b8184ff87676988f8b774d464d80c96c4f8483781c7ce`; concatenated A+A chain: `eddc513d4f1d4bcbc8b268db1347437d66f7f01071e3c82c5020772ab71ad34c`.

The render sequence was `format=yuv420p,hwupload,libplacebo=w=1920:h=1080:format=rgba[:custom_shader_path=CHAIN],hwdownload,format=rgba,select=eq(n\,24)`. The 24 preceding frames allow Salow's temporal state to develop; each arm starts from the same seek point. Logs recorded registration of the requested shader passes, and image differences were checked. This is a visual demonstration, not a motion test or a fresh timing benchmark. The concatenated A+A chain is the project's A+A reference; it is not the separate Anime4K HQ configuration.
