#!/usr/bin/env python3
"""Create this app's first upload key without printing passwords or overwriting keys."""
import argparse
import os
from pathlib import Path
import secrets
import shutil
import subprocess


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--first-upload', action='store_true',
                        help='Confirm no prior Play upload requires an existing key.')
    args = parser.parse_args()
    if not args.first_upload:
        parser.error('Reuse your existing upload key unless this is the first Play upload.')
    root = Path(__file__).resolve().parents[1]
    private = Path.home() / '.qorgan/signing'
    key = private / 'upload-keystore.jks'
    password_file = private / 'upload.password'
    properties = root / 'android/key.properties'
    for path in (key, password_file, properties):
        if path.exists():
            raise SystemExit('Refusing to overwrite existing signing material: ' + str(path))
    java_home = os.environ.get('JAVA_HOME')
    keytool = str(Path(java_home) / 'bin/keytool') if java_home else shutil.which('keytool')
    if not keytool:
        raise SystemExit('keytool not found. Install Java 17 first.')
    os.umask(0o077)
    private.mkdir(mode=0o700, parents=True, exist_ok=True)
    password = secrets.token_urlsafe(36)
    # Exclusive creation and restrictive permissions avoid both accidental
    # replacement and passwords in shell arguments/process listings.
    with password_file.open('x') as file:
        file.write(password + '\n')
    subprocess.run([
        keytool, '-genkeypair', '-noprompt', '-keystore', str(key),
        '-storetype', 'JKS', '-keyalg', 'RSA', '-keysize', '3072',
        '-validity', '10000', '-alias', 'upload', '-dname', 'CN=Azamat',
        '-storepass:file', str(password_file), '-keypass:file', str(password_file),
    ], check=True)
    with properties.open('x') as file:
        file.write(f'storeFile={key}\nstorePassword={password}\nkeyAlias=upload\nkeyPassword={password}\n')
    public = root / 'artifacts/play-release'
    public.mkdir(parents=True, exist_ok=True)
    certificate = public / 'upload-certificate.pem'
    subprocess.run([
        keytool, '-exportcert', '-rfc', '-keystore', str(key), '-alias', 'upload',
        '-storepass:file', str(password_file), '-file', str(certificate),
    ], check=True)
    print('Created private upload key: ' + str(key))
    print('Password saved privately in the same directory; it was not printed.')
    print('Public upload certificate: ' + str(certificate))
    print('Back up the private directory securely before uploading to Play.')


if __name__ == '__main__':
    main()
