import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'blocklist_store.dart';

/// The list Qorgan fetches. Aggregates OpenPhish, IPThreat and PhishTank;
/// refreshed upstream twice a day. The data is CC BY-SA 4.0 — see
/// THIRD_PARTY_NOTICES.md. Serving this from our own host is what would let us
/// sign it; see docs/blocklist.md.
final blocklistFeed = Uri.parse(
  'https://malware-filter.gitlab.io/malware-filter/phishing-filter-hosts.txt',
);

/// What happened on an update attempt. Reported rather than thrown so the UI
/// can stay quiet about a routine "nothing to do".
enum BlocklistUpdate {
  /// A new list is in place.
  applied,

  /// The interval has not elapsed; nothing was fetched.
  tooSoon,

  /// A response arrived but failed a check, so the previous list was kept.
  rejected,

  /// The fetch itself failed. The previous list was kept.
  failed,
}

/// When the list was last replaced. Kept behind an interface so tests do not
/// need a platform channel.
abstract interface class BlocklistUpdateLog {
  Future<DateTime?> read();
  Future<void> write(DateTime at);
}

class MemoryUpdateLog implements BlocklistUpdateLog {
  DateTime? _at;

  @override
  Future<DateTime?> read() async => _at;

  @override
  Future<void> write(DateTime at) async => _at = at;
}

/// Survives process death, which matters because the app is killed constantly.
class StoredUpdateLog implements BlocklistUpdateLog {
  final _preferences = SharedPreferencesAsync();
  static const _key = 'qorgan.blocklist.updatedAt';

  @override
  Future<DateTime?> read() async {
    final value = await _preferences.getInt(_key);
    return value == null ? null : DateTime.fromMillisecondsSinceEpoch(value);
  }

  @override
  Future<void> write(DateTime at) =>
      _preferences.setInt(_key, at.millisecondsSinceEpoch);
}

/// Fetches the current phishing list and replaces the stored one.
///
/// Never call this from the SMS receiver: it has a nine-second budget and a
/// network round trip does not belong in it. The app updates in the
/// foreground; the receiver only reads whatever is already stored.
class BlocklistUpdater {
  BlocklistUpdater({
    required this.store,
    required this.source,
    required this.fetch,
    this.expectedSha256,
    this.interval = const Duration(hours: 12),
    this.minimumHosts = 1000,
    BlocklistUpdateLog? log,
  }) : log = log ?? MemoryUpdateLog();

  final SqliteBlocklist store;

  /// Must be HTTPS. The URL is constant: it carries nothing about the device.
  final Uri source;
  final Future<String> Function(Uri source) fetch;

  /// Digest of the expected body, when the feed publishes one. This catches a
  /// truncated or corrupted download. It is NOT protection against someone who
  /// controls the connection — that needs a signature over a key we own, which
  /// in turn needs the list served from our own host. See docs/blocklist.md.
  final String? expectedSha256;

  /// The upstream feed refreshes twice a day; polling faster only costs
  /// battery and bandwidth.
  final Duration interval;

  /// A list far below this is treated as truncated. Silently shrinking to
  /// nothing is the dangerous failure: protection would quietly stop working.
  final int minimumHosts;

  final BlocklistUpdateLog log;

  Future<BlocklistUpdate> update({DateTime? now}) async {
    if (!source.isScheme('https')) {
      throw ArgumentError.value(
        source.toString(),
        'source',
        'the blocklist must be fetched over https',
      );
    }

    final at = now ?? DateTime.now();
    final last = await log.read();
    if (last != null && at.difference(last) < interval) {
      return BlocklistUpdate.tooSoon;
    }

    final String body;
    try {
      body = await fetch(source);
    } catch (_) {
      // Offline is the normal case, not an error worth surfacing.
      return BlocklistUpdate.failed;
    }

    if (expectedSha256 != null) {
      final digest = sha256.convert(utf8.encode(body)).toString();
      if (digest != expectedSha256) return BlocklistUpdate.rejected;
    }

    final hosts = parseHostList(body);
    if (hosts.length < minimumHosts) return BlocklistUpdate.rejected;

    await store.replaceAll(hosts);
    await log.write(at);
    return BlocklistUpdate.applied;
  }
}

/// The default transport. `dart:io` keeps this dependency-free; the updater
/// takes the fetch as a function so tests never touch the network.
Future<String> fetchOverHttps(Uri source) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
  try {
    final response = await client.getUrl(source).then((r) => r.close());
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('${response.statusCode}', uri: source);
    }
    // Awaited inside the try: `finally` must not close the client while the
    // body is still being read.
    return await response.transform(utf8.decoder).join();
  } finally {
    client.close();
  }
}
