#!/bin/sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
config=${XDG_CONFIG_HOME:-"$HOME/.config"}/mpv
parent=$(dirname -- "$config")
mkdir -p "$parent"
stage=$(mktemp -d "$parent/.salow-install.XXXXXX")
trap 'rm -rf -- "$stage"' EXIT HUP INT TERM
cp -R "$root/mpv-config/." "$stage/"
cp "$root/shaders/salow.hook" "$root/shaders/salow-medium.hook" "$root/shaders/tv-dynamic.glsl" "$stage/shaders/"
# Preserve user-supplied impulse responses and remembered toggle choices on upgrades.
if [ -d "$config/irs" ]; then cp -R "$config/irs" "$stage/irs"; fi
if [ -f "$config/salow-state.json" ]; then cp "$config/salow-state.json" "$stage/"; fi
backup=
if [ -e "$config" ] || [ -L "$config" ]; then
    backup=$(mktemp -d "$parent/mpv.backup-$(date +%Y%m%d-%H%M%S).XXXXXX")
    mv "$config" "$backup/mpv"
fi
if ! mv "$stage" "$config"; then
    if [ -n "$backup" ]; then mv "$backup/mpv" "$config"; fi
    exit 1
fi
trap - EXIT HUP INT TERM
if [ -n "$backup" ]; then printf 'Previous configuration: %s/mpv\n' "$backup"; fi
printf 'Installed mpv configuration in %s. See README.md for dependencies.\n' "$config"
