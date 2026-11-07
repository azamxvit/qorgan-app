"""Guard against pairing a stale phone-test APK with a new Play bundle."""
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location(
    'inspection', Path(__file__).parents[1] / 'inspect_play_release.py')
inspection = importlib.util.module_from_spec(spec)
spec.loader.exec_module(inspection)


class ReleaseIdentityTest(unittest.TestCase):
    def test_same_identity(self):
        inspection.verify_apk_identity(
            "package: name='kz.qorgan.qorgan_app' versionCode='1' versionName='1.0.0'\n",
            'kz.qorgan.qorgan_app', '1', '1.0.0')

    def test_mismatch_or_missing_identity_is_rejected(self):
        for package, code, name in [
            ('another.app', '1', '1.0.0'),
            ('kz.qorgan.qorgan_app', '2', '1.0.0'),
            ('kz.qorgan.qorgan_app', '1', '1.1.0'),
        ]:
            with self.subTest(package=package, code=code, name=name):
                with self.assertRaises(SystemExit):
                    inspection.verify_apk_identity(
                        f"package: name='{package}' versionCode='{code}' versionName='{name}'\n",
                        'kz.qorgan.qorgan_app', '1', '1.0.0')
        with self.assertRaises(SystemExit):
            inspection.verify_apk_identity('', 'kz.qorgan.qorgan_app', '1', '1.0.0')


if __name__ == '__main__':
    unittest.main()
