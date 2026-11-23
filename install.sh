#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
config=${XDG_CONFIG_HOME:-"$HOME/.config"}/mpv
mkdir -p "$config/shaders"
for shader in salow.hook salow-medium.hook tv-dynamic.glsl; do
    if [ -e "$config/shaders/$shader" ]; then
        printf 'Already exists: %s\nRemove or rename it before installing.\n' "$config/shaders/$shader" >&2
        exit 1
    fi
done
cp "$root/shaders/salow.hook" "$root/shaders/salow-medium.hook" "$root/shaders/tv-dynamic.glsl" "$config/shaders/"
printf 'Installed shaders in %s/shaders. See README.md to enable them.\n' "$config"
