/// Owner-approved public details, overridable by the release build.
/// Explicitly empty values omit the corresponding block in debug builds.
const qorganDeveloperName = String.fromEnvironment(
  'QORGAN_DEVELOPER_NAME',
  defaultValue: 'Azamat',
);
const qorganSupportEmail = String.fromEnvironment(
  'QORGAN_SUPPORT_EMAIL',
  defaultValue: 'omirtayazamatt@gmail.com',
);
const qorganPrivacyUrl = String.fromEnvironment(
  'QORGAN_PRIVACY_URL',
  defaultValue: 'https://qorgan-web.vercel.app/privacy',
);

/// Show only a hosted web address; never a local file or an executable scheme.
String? get hostedPrivacyUrl {
  final value = qorganPrivacyUrl.trim();
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !(uri.isScheme('https') || uri.isScheme('http')) ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return null;
  }
  return value;
}
