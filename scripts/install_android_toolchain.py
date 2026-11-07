#!/usr/bin/env python3
"""Install the pinned Android build tools in persistent user directories.

Downloads come from Google and Eclipse Adoptium; checksums are verified before
extraction. Run with --accept-sdk-licenses only after accepting the Android SDK
license at https://developer.android.com/studio/terms . Does not change shell
profiles, Flutter global settings, or an existing JDK installation.
"""
import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import zipfile

SDK_URL = 'https://dl.google.com/android/repository/commandlinetools-mac_x86_64-16111833_latest.zip'
SDK_SHA1 = '112cf9618794a997ff273537d55bee02c22abffe'
JDK_URL = ('https://github.com/adoptium/temurin17-binaries/releases/download/'
           'jdk-17.0.21%2B9/OpenJDK17U-jdk_aarch64_mac_hotspot_17.0.21_9.tar.gz')
JDK_SHA256 = '78b08c7f5a0598242d5719c022e19479cb4a3aa45c37c19726a757a469ed1c15'
PACKAGES = ['platform-tools', 'platforms;android-36', 'build-tools;36.0.0',
            'ndk;28.2.13676358']


def download(url, target, algorithm, expected):
    if not target.exists():
        partial = target.with_suffix(target.suffix + '.partial')
        print('Downloading ' + target.name, flush=True)
        # macOS curl uses the system certificate store; some Python installs
        # have no CA bundle. Certificate verification stays enabled.
        subprocess.run(['curl', '-fL', '--retry', '2', '--connect-timeout', '20',
                        '--max-time', '1200', url, '-o', str(partial)], check=True)
        partial.replace(target)
    digest = hashlib.new(algorithm)
    with target.open('rb') as source:
        for block in iter(lambda: source.read(1024 * 1024), b''):
            digest.update(block)
    if digest.hexdigest() != expected:
        raise SystemExit('Checksum mismatch; refusing to install ' + str(target))
    print('Checksum verified: ' + target.name, flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--accept-sdk-licenses', action='store_true')
    args = parser.parse_args()
    if not args.accept_sdk_licenses:
        parser.error('--accept-sdk-licenses is required; read https://developer.android.com/studio/terms first')
    if os.uname().sysname != 'Darwin' or os.uname().machine != 'arm64':
        parser.error('This pinned bootstrap targets Apple Silicon macOS only.')
    sdk = Path.home() / 'Library/Android/sdk'
    java_root = Path.home() / 'Library/Java/JavaVirtualMachines'
    java_home = java_root / 'jdk-17.0.21+9/Contents/Home'
    cache = Path('/tmp/qorgan-release-downloads')
    cache.mkdir(parents=True, exist_ok=True)
    if not (java_home / 'bin/java').exists():
        archive = cache / 'temurin17-mac-arm64.tar.gz'
        download(JDK_URL, archive, 'sha256', JDK_SHA256)
        java_root.mkdir(parents=True, exist_ok=True)
        with tarfile.open(archive) as tar:
            tar.extractall(java_root, filter='data')
    if not (java_home / 'bin/java').exists():
        raise SystemExit('Unexpected JDK archive layout: ' + str(java_home))
    manager = sdk / 'cmdline-tools/23.0/bin/sdkmanager'
    if not manager.exists():
        archive = cache / 'android-command-tools-23.zip'
        download(SDK_URL, archive, 'sha1', SDK_SHA1)
        staging = cache / 'command-tools-23'
        with zipfile.ZipFile(archive) as z:
            z.extractall(staging)
        manager.parent.parent.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(staging / 'cmdline-tools'), str(manager.parent.parent))
        for executable in manager.parent.iterdir():
            if executable.is_file():
                executable.chmod(0o755)
    env = dict(os.environ, JAVA_HOME=str(java_home), ANDROID_HOME=str(sdk))
    env['PATH'] = str(java_home / 'bin') + os.pathsep + env.get('PATH', '')
    subprocess.run([str(java_home / 'bin/java'), '-version'], check=True, env=env)
    subprocess.run([str(manager), '--sdk_root=' + str(sdk), '--licenses'],
                   input='y\n' * 100, text=True, check=True, env=env)
    subprocess.run([str(manager), '--sdk_root=' + str(sdk), *PACKAGES], check=True, env=env)
    properties = Path(__file__).resolve().parents[1] / 'android/local.properties'
    lines = properties.read_text().splitlines() if properties.exists() else []
    lines = [line for line in lines if not line.startswith('sdk.dir=')]
    lines.append('sdk.dir=' + str(sdk))
    properties.write_text('\n'.join(lines) + '\n')
    print('Android SDK: ' + str(sdk))
    print('JAVA_HOME: ' + str(java_home))
    print('Installed packages: ' + ', '.join(PACKAGES))


if __name__ == '__main__':
    main()
