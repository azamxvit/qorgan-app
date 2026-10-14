"""Exercise the release APK on an Android emulator, never a physical phone.
Usage: python3 scripts/validate_android.py --adb /path/to/adb --apk /path/to.apk
"""
import argparse
import json
import re
import subprocess
import time
import xml.etree.ElementTree as ET
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--adb', required=True)
parser.add_argument('--apk', required=True)
parser.add_argument('--serial', default='emulator-5554')
parser.add_argument('--reboot', action='store_true')
parser.add_argument('--out', default='/private/tmp/qorgan-toolchain/validation')
args = parser.parse_args()
if not args.serial.startswith('emulator-'):
    raise SystemExit('This test is restricted to emulator devices.')
out = Path(args.out)
out.mkdir(parents=True, exist_ok=True)
package = 'kz.qorgan.qorgan_app'

def adb(*parts):
    return subprocess.check_output([args.adb, '-s', args.serial, *parts], text=True, timeout=30)

def ui():
    adb('shell', 'uiautomator', 'dump', '/sdcard/qorgan-ui.xml')
    xml = adb('shell', 'cat', '/sdcard/qorgan-ui.xml')
    return ET.fromstring(xml)

def labels(root):
    return [node.get('content-desc') or node.get('text') or '' for node in root.iter('node')]

def tap(label):
    root = ui()
    for node in root.iter('node'):
        if node.get('content-desc') == label and node.get('enabled') == 'true':
            x1, y1, x2, y2 = map(int, re.findall(r'\d+', node.get('bounds')))
            adb('shell', 'input', 'tap', str((x1+x2)//2), str((y1+y2)//2))
            return
    raise AssertionError('Button not ready: '+label+'; '+repr(labels(root)))

def warnings():
    raw = adb('shell', 'dumpsys', 'notification', '--noredact')
    # Active NotificationRecord lines only, excluding the history section.
    active = raw.split('Historical notifications:')[0]
    return [line.strip() for line in active.splitlines()
            if 'NotificationRecord(' in line and 'pkg='+package in line and 'GROUP_SUMMARY' not in line]

def wait_warning_count(count):
    for _ in range(15):
        records = warnings()
        if len(records) == count:
            return records
        time.sleep(1)
    raise AssertionError('Expected '+str(count)+' active Qorgan warnings; found '+repr(warnings()))

print(adb('install', '-r', '-g', args.apk), flush=True)
adb('shell', 'pm', 'clear', package)
adb('shell', 'pm', 'grant', package, 'android.permission.RECEIVE_SMS')
adb('shell', 'pm', 'grant', package, 'android.permission.POST_NOTIFICATIONS')
adb('shell', 'am', 'force-stop', package)
adb('shell', 'input', 'keyevent', 'KEYCODE_WAKEUP')
adb('shell', 'input', 'keyevent', 'KEYCODE_MENU')
adb('shell', 'am', 'start', '-n', package+'/.MainActivity')
time.sleep(3)
root = ui()
if not any('Защита включена' in text for text in labels(root)):
    tap('Включить защиту')
time.sleep(1)
assert any('Защита включена' in text for text in labels(ui())), 'Protection did not become active'
print('PASS: release UI starts and protection becomes active', flush=True)

adb('emu', 'sms', 'send', '+77001234567', 'Halyk Bank: Deposit 20000')
time.sleep(3)
assert len(warnings()) == 0, 'Ordinary SMS unexpectedly warned'
print('PASS: ordinary SMS does not warn', flush=True)

adb('emu', 'sms', 'send', '+77001234567', 'KASPI: http://evil.example/foreground')
wait_warning_count(1)
print('PASS: suspicious SMS warns in foreground', flush=True)

adb('shell', 'input', 'keyevent', 'KEYCODE_HOME')
# Android may briefly retain broadcast importance; wait until the process is killable.
for _ in range(12):
    adb('shell', 'am', 'kill', package)
    time.sleep(2)
    process = subprocess.run([args.adb, '-s', args.serial, 'shell', 'pidof', package], capture_output=True, text=True)
    if process.returncode != 0 or not process.stdout.strip():
        break
else:
    raise AssertionError('App process still alive before cold delivery')
adb('shell', 'input', 'keyevent', 'KEYCODE_SLEEP')
adb('emu', 'sms', 'send', '+77001234567', 'KASPI: http://evil.example/cold-background')
records = wait_warning_count(2)
print('PASS: suspicious SMS warns after process death with screen off', flush=True)

adb('shell', 'input', 'keyevent', 'KEYCODE_WAKEUP')
adb('shell', 'input', 'keyevent', 'KEYCODE_MENU')
adb('shell', 'am', 'start', '-n', package+'/.MainActivity')
time.sleep(2)
tap('Выключить защиту')
time.sleep(1)
adb('shell', 'input', 'keyevent', 'KEYCODE_HOME')
for _ in range(12):
    adb('shell', 'am', 'kill', package)
    time.sleep(2)
    process = subprocess.run([args.adb, '-s', args.serial, 'shell', 'pidof', package], capture_output=True, text=True)
    if process.returncode != 0 or not process.stdout.strip():
        break
else:
    raise AssertionError('App process still alive before disabled test')
adb('emu', 'sms', 'send', '+77001234567', 'KASPI: http://evil.example/disabled')
time.sleep(4)
assert len(warnings()) == 2, 'Disabled protection posted a warning'
adb('shell', 'am', 'start', '-n', package+'/.MainActivity')
time.sleep(2)
assert not any('Защита включена' in text for text in labels(ui())), 'Disabled state did not persist'
print('PASS: disabled state survives process death and suppresses warnings', flush=True)
if args.reboot:
    tap('Включить защиту')
    time.sleep(1)
    assert any('Защита включена' in text for text in labels(ui()))
    adb('shell', 'input', 'keyevent', 'KEYCODE_HOME')
    adb('reboot')
    print('Checking restart and first unlock without opening Qorgan...', flush=True)
    deadline = time.monotonic() + 120
    while time.monotonic() < deadline:
        try:
            if adb('shell', 'getprop', 'sys.boot_completed').strip() == '1':
                break
        except (subprocess.CalledProcessError, subprocess.TimeoutExpired):
            pass
        time.sleep(2)
    else:
        raise AssertionError('Emulator did not reboot in time')
    adb('shell', 'input', 'keyevent', 'KEYCODE_WAKEUP')
    adb('shell', 'input', 'keyevent', 'KEYCODE_MENU')
    time.sleep(3)
    before = subprocess.run([args.adb, '-s', args.serial, 'shell', 'pidof', package], capture_output=True, text=True)
    assert not before.stdout.strip(), 'Qorgan started before the post-reboot SMS test'
    adb('emu', 'sms', 'send', '+77001234567', 'KASPI: http://evil.example/after-reboot')
    records = wait_warning_count(1)
    print('PASS: SMS warns after reboot and first unlock without opening Qorgan', flush=True)
raw = adb('shell', 'dumpsys', 'notification', '--noredact')
(out/'notifications.txt').write_text(raw)
(out/'results.json').write_text(json.dumps({
    'serial': args.serial, 'android_sdk': adb('shell', 'getprop', 'ro.build.version.sdk').strip(),
    'foreground_warning': True, 'ordinary_no_warning': True,
    'process_absent_before_sms': True, 'screen_off_cold_warning': True,
    'disabled_after_process_death_no_warning': True, 'disabled_state_restored': True,
    'reboot_first_unlock_warning': args.reboot,
    'warning_records': records,
}, indent=2))
print('Evidence: '+str(out), flush=True)
