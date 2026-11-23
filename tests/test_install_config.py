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
        assert result.returncode == 0, result.stderr
        assert (config / 'mpv.conf').is_file()
        assert (config / 'shaders/salow.hook').is_file()
        assert not (config / 'mpv-config').exists()
        for name in ('xfi-crystalizer.wav', 'dolby-atmos.wav'):
            assert (config / 'irs' / name).read_bytes() == (installer.parent / 'mpv-config/irs' / name).read_bytes()
        assert not (config / 'irs/razor-surround.wav').exists()
        backups = list(base.glob('mpv.backup-*/mpv'))
        assert len(backups) == (0 if case == 'missing' else 1)
        if case in ('settings', 'hidden'):
            assert (backups[0] / marker.name).read_text() == 'keep me'
        elif case == 'file':
            assert backups[0].read_text() == 'keep me'
        elif case == 'symlink':
            assert backups[0].is_symlink() and not list(target.iterdir())
        print(case + ': passed')
    base = Path(scratch) / 'upgrade'
    config = base / 'mpv'
    (config / 'irs').mkdir(parents=True)
    (config / 'irs/xfi-crystalizer.wav').write_bytes(b'user supplied response')
    (config / 'salow-state.json').write_text('{"audio":"original","pan":true}')
    result = subprocess.run(['sh', str(installer)], env={**os.environ, 'XDG_CONFIG_HOME': str(base)}, capture_output=True, text=True)
    assert result.returncode == 0, result.stderr
    assert (config / 'irs/xfi-crystalizer.wav').read_bytes() == b'user supplied response'
    assert not (config / 'irs/irs').exists()
    assert (config / 'irs/dolby-atmos.wav').is_file()
    assert (config / 'salow-state.json').read_text() == '{"audio":"original","pan":true}'
    print('Upgrade preserves audio files and choices: passed')
