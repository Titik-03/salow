# pan-smooth.vpy — mpv --vf=vapoursynth filter; code in pansmooth_core.py (same folder).
# Interpolates camera pans/slides only (24 -> 60 fps); toggled with Alt+2.
import os, sys
sys.path.insert(0, os.path.join(os.environ.get('XDG_CONFIG_HOME', os.path.expanduser('~/.config')), 'mpv', 'vs'))
import pansmooth_core
pansmooth_core.run(video_in, globals().get('container_fps')).set_output()
