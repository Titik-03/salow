"""Run with python3 tests/test_install_config.py; never touches real mpv settings."""
import os
from pathlib import Path
import subprocess
import tempfile

installer = Path(__file__).resolve().parents[1] / 'install-config.sh'
with tempfile.TemporaryDirectory() as scratch:
    for case in ('missing', 'empty', 'settings', 'hidden', 'file', 'symlink'):
        base = Path(scratch) / case
        base.mkdir()
        config = base / 'mpv'
        if case in ('empty', 'settings', 'hidden'):
            config.mkdir()
        if case in ('settings', 'hidden'):
            marker = config / ('mpv.conf' if case == 'settings' else '.keep')
            marker.write_text('keep me')
        if case == 'file':
            config.write_text('keep me')
        if case == 'symlink':
            target = base / 'target'
            target.mkdir()
            config.symlink_to(target, target_is_directory=True)
        result = subprocess.run(['sh', str(installer)], env={**os.environ, 'XDG_CONFIG_HOME': str(base)}, capture_output=True, text=True)
        if case in ('missing', 'empty'):
            assert result.returncode == 0, result.stderr
            assert (config / 'mpv.conf').is_file()
            assert (config / 'shaders/salow.hook').is_file()
            assert not (config / 'mpv-config').exists()
        else:
            assert result.returncode != 0, case
            if case in ('settings', 'hidden'):
                assert marker.read_text() == 'keep me'
            elif case == 'file':
                assert config.read_text() == 'keep me'
            else:
                assert config.is_symlink() and not list(target.iterdir())
        print(case + ': passed')
