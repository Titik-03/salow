#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
config=${XDG_CONFIG_HOME:-"$HOME/.config"}/mpv
if [ -e "$config" ]; then
    printf 'Already exists: %s\nRename or back up this directory before installing.\n' "$config" >&2
    exit 1
fi
mkdir -p "$(dirname -- "$config")"
cp -R "$root/mpv-config" "$config"
cp "$root/shaders/salow.hook" "$root/shaders/salow-medium.hook" "$root/shaders/tv-dynamic.glsl" "$config/shaders/"
printf 'Installed mpv configuration in %s. See README.md for dependencies.\n' "$config"
