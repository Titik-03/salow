#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
config=${XDG_CONFIG_HOME:-"$HOME/.config"}/mpv
if [ -L "$config" ] || { [ -e "$config" ] && [ ! -d "$config" ]; }; then
    printf 'Not a regular directory: %s\nMove it aside before installing.\n' "$config" >&2
    exit 1
fi
mkdir -p "$config"
if [ -n "$(find "$config" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
    printf 'Configuration directory is not empty: %s\nRename or back it up before installing.\n' "$config" >&2
    exit 1
fi
cp -R "$root/mpv-config/." "$config/"
cp "$root/shaders/salow.hook" "$root/shaders/salow-medium.hook" "$root/shaders/tv-dynamic.glsl" "$config/shaders/"
printf 'Installed mpv configuration in %s. See README.md for dependencies.\n' "$config"
