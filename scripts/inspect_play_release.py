#!/usr/bin/env python3
"""Validate a signed AAB/APK and write public, reproducible release evidence."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import struct
import subprocess
import xml.etree.ElementTree as ET
import zipfile


def run(command):
    return subprocess.check_output(command, text=True, stderr=subprocess.STDOUT)


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def verify_apk_identity(badging, package, version_code, version_name):
    match = re.search(r"^package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", badging, re.M)
    require(match is not None, 'Cannot read APK identity.')
    require(match.groups() == (package, version_code, version_name),
            'APK package/version does not match the AAB; rebuild both from the same source.')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--aab', required=True, type=Path)
    parser.add_argument('--apk', required=True, type=Path)
    parser.add_argument('--bundletool', required=True, type=Path)
    parser.add_argument('--certificate', type=Path,
                        default=Path('artifacts/play-release/upload-certificate.pem'))
    args = parser.parse_args()
    java_home = os.environ.get('JAVA_HOME')
    if not java_home:
        java_home = run(['/usr/libexec/java_home', '-v', '17']).strip()
    java = str(Path(java_home) / 'bin/java')
    keytool = str(Path(java_home) / 'bin/keytool')
    sdk = Path(os.environ.get('ANDROID_HOME', str(Path.home() / 'Library/Android/sdk')))
    android_tools = sdk / 'build-tools/36.0.0'
    require(hashlib.sha256(args.bundletool.read_bytes()).hexdigest() ==
            'a099cfa1543f55593bc2ed16a70a7c67fe54b1747bb7301f37fdfd6d91028e29',
            'Use the official bundletool-all-1.18.3.jar with the documented checksum.')
    bundle = [java, '-jar', str(args.bundletool)]
    run(bundle + ['validate', '--bundle=' + str(args.aab)])
    manifest_xml = run(bundle + ['dump', 'manifest', '--bundle=' + str(args.aab)])
    manifest = ET.fromstring(manifest_xml)
    android = '{http://schemas.android.com/apk/res/android}'
    require(manifest.get('package') == 'kz.qorgan.qorgan_app', 'Unexpected package ID.')
    uses_sdk = manifest.find('uses-sdk')
    require(uses_sdk.get(android + 'targetSdkVersion') == '36', 'Unexpected target SDK.')
    require(uses_sdk.get(android + 'minSdkVersion') == '24', 'Unexpected minimum SDK.')
    permissions = sorted(p.get(android + 'name') for p in manifest.findall('uses-permission'))
    expected = {
        'android.permission.RECEIVE_SMS', 'android.permission.POST_NOTIFICATIONS',
        'android.permission.INTERNET', 'android.permission.VIBRATE',
        'kz.qorgan.qorgan_app.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION',
    }
    require(set(permissions) == expected, 'Review changed permissions: ' + repr(permissions))
    application = manifest.find('application')
    require(application.get(android + 'allowBackup') == 'false', 'Backup must remain disabled.')
    require(application.get(android + 'debuggable', 'false') == 'false', 'Release is debuggable.')
    receiver = next((x for x in application.findall('receiver')
                     if x.get(android + 'name') == 'com.shounakmulay.telephony.sms.IncomingSmsReceiver'), None)
    require(receiver is not None and receiver.get(android + 'permission') == 'android.permission.BROADCAST_SMS',
            'Background SMS receiver missing or insufficiently protected.')
    config = json.loads(run(bundle + ['dump', 'config', '--bundle=' + str(args.aab)]))
    require(config['optimizations']['uncompressNativeLibraries']['alignment'] == 'PAGE_ALIGNMENT_16K',
            'App Bundle must request 16 KB native-library alignment.')
    signature_output = run([str(Path(java_home) / 'bin/jarsigner'), '-verify', '-verbose', '-certs', str(args.aab)])
    require('jar verified.' in signature_output and 'unsigned entries' not in signature_output,
            'AAB signature verification failed or contains unsigned content.')
    certificate = run([keytool, '-printcert', '-file', str(args.certificate)])
    signed = run([keytool, '-printcert', '-jarfile', str(args.aab)])
    require('Android Debug' not in signed, 'Debug certificate must never be submitted to Play.')
    fingerprint = re.search(r'SHA256:\s*([A-Fa-f0-9:]+)', certificate)[1].replace(':', '').lower()
    require(fingerprint == re.search(r'SHA256:\s*([A-Fa-f0-9:]+)', signed)[1].replace(':', '').lower(),
            'AAB signer does not match the upload certificate.')
    env = dict(os.environ, JAVA_HOME=java_home)
    apk_signature = subprocess.check_output([str(android_tools / 'apksigner'), 'verify',
                                             '--verbose', '--print-certs', str(args.apk)],
                                            text=True, stderr=subprocess.STDOUT, env=env)
    require('Number of signers: 1' in apk_signature and
            ('Signer #1 certificate SHA-256 digest: ' + fingerprint) in apk_signature,
            'APK must have the same single upload signer.')
    verify_apk_identity(
        run([str(android_tools / 'aapt2'), 'dump', 'badging', str(args.apk)]),
        manifest.get('package'), manifest.get(android + 'versionCode'),
        manifest.get(android + 'versionName'))
    run([str(android_tools / 'zipalign'), '-c', '-P', '16', '-v', '4', str(args.apk)])
    natives = []
    with zipfile.ZipFile(args.aab) as archive:
        for name in archive.namelist():
            if not name.endswith('.so') or not any('/' + abi + '/' in name for abi in ('arm64-v8a', 'x86_64')):
                continue
            data = archive.read(name)
            require(data[:6] == b'\x7fELF\x02\x01', 'Unexpected ELF header: ' + name)
            offset = struct.unpack_from('<Q', data, 32)[0]
            size, count = struct.unpack_from('<HH', data, 54)
            alignments = []
            for index in range(count):
                header = struct.unpack_from('<IIQQQQQQ', data, offset + index * size)
                if header[0] == 1:  # PT_LOAD
                    require(header[7] >= 16384 and header[2] % 16384 == header[3] % 16384,
                            'ELF is not 16 KB aligned: ' + name)
                    alignments.append(header[7])
            require(bool(alignments), 'No load segments found: ' + name)
            natives.append({'file': name, 'load_segment_alignment': alignments})
    require(bool(natives), 'No 64-bit native libraries found in Flutter release.')
    report = {
        'package': manifest.get('package'),
        'version_name': manifest.get(android + 'versionName'),
        'version_code': manifest.get(android + 'versionCode'),
        'min_sdk': 24, 'target_sdk': 36, 'permissions': permissions,
        'upload_certificate_sha256': fingerprint, 'bundletool_version': '1.18.3',
        'bundle_valid': True, 'aab_signature_valid': True, 'apk_signature_matches': True,
        'apk_identity_matches': True,
        'apk_zip_alignment_16kb': True, 'bundle_native_alignment_16kb': True,
        'native_libraries': natives,
        'artifacts': [{'file': str(p), 'bytes': p.stat().st_size,
                       'sha256': hashlib.sha256(p.read_bytes()).hexdigest()} for p in (args.aab, args.apk)],
        'limitations': ['Static package checks only; not a real-device or 16 KB runtime test.',
                        'Not Google Play permission approval or production access.'],
    }
    out = args.aab.parent
    (out / 'release-manifest.xml').write_text(manifest_xml)
    (out / 'verification.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
