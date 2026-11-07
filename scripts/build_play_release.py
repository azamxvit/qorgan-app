#!/usr/bin/env python3
"""Build the signed Play AAB, optionally also an APK for device verification."""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
from urllib.parse import urlparse


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apk', action='store_true', help='Also build a same-version signed APK.')
    parser.add_argument('--config', default='config/play-release.json')
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    config_path = root / args.config
    config = json.loads(config_path.read_text())
    for key in ('QORGAN_DEVELOPER_NAME', 'QORGAN_SUPPORT_EMAIL', 'QORGAN_PRIVACY_URL'):
        if not isinstance(config.get(key), str) or not config[key].strip():
            raise SystemExit('Missing public release information: ' + key)
    if not re.fullmatch(r'[^\s@]+@[^\s@]+\.[^\s@]+', config['QORGAN_SUPPORT_EMAIL']):
        raise SystemExit('A real support email is required.')
    policy = urlparse(config['QORGAN_PRIVACY_URL'])
    if policy.scheme != 'https' or not policy.hostname or policy.username or policy.password:
        raise SystemExit('Privacy policy must use a public HTTPS URL without credentials.')
    env = dict(os.environ)
    if env.get('ORG_GRADLE_PROJECT_qorganSmokeSigning') == 'true':
        raise SystemExit('Refusing smoke signing for a Play release.')
    if not env.get('JAVA_HOME') and os.uname().sysname == 'Darwin':
        env['JAVA_HOME'] = subprocess.check_output(['/usr/libexec/java_home', '-v', '17'], text=True).strip()
    env.setdefault('ANDROID_HOME', str(Path.home() / 'Library/Android/sdk'))
    if not (Path(env['ANDROID_HOME']) / 'platforms/android-36/android.jar').is_file():
        raise SystemExit('Android SDK 36 is missing. See scripts/install_android_toolchain.py.')
    version_match = re.search(r'^version:\s*(\S+)\s*$', (root / 'pubspec.yaml').read_text(), re.M)
    if not version_match or not re.fullmatch(r'\d+\.\d+\.\d+\+\d+', version_match[1]):
        raise SystemExit('pubspec.yaml needs an explicit version and build number.')
    version, number = version_match[1].split('+')
    out = root / 'artifacts/play-release'
    out.mkdir(parents=True, exist_ok=True)
    for kind in ['appbundle'] + (['apk'] if args.apk else []):
        subprocess.run(['flutter', 'build', kind, '--release', '--no-pub',
                        '--dart-define-from-file=' + str(config_path)],
                       cwd=root, env=env, check=True)
        source = (root / 'build/app/outputs/bundle/release/app-release.aab' if kind == 'appbundle'
                  else root / 'build/app/outputs/flutter-apk/app-release.apk')
        target = out / f'qorgan-{version}-{number}{source.suffix}'
        shutil.copy2(source, target)
        print('Prepared ' + str(target), flush=True)
    print('Inspect the artifacts and confirm the public policy before uploading; see docs/google-play/.')


if __name__ == '__main__':
    main()
