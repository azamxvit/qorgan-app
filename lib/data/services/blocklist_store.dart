import 'package:flutter/services.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite/sqflite.dart';

/// Hosts already reported for phishing.
abstract interface class Blocklist {
  /// Which of [hosts] are known for phishing, answered with the hosts exactly
  /// as they appeared in the message so the rule can compare them directly.
  Future<Set<String>> blockedAmong(Iterable<String> hosts);
}

/// Nothing is known. Used where no list is available, so the word-based rule
/// still runs instead of the check failing shut.
class EmptyBlocklist implements Blocklist {
  const EmptyBlocklist();

  @override
  Future<Set<String>> blockedAmong(Iterable<String> hosts) async => const {};
}

/// The asset that makes a fresh install useful before it ever sees a network.
const blocklistSeedAsset = 'assets/blocklist/seed-hosts.txt';

/// Entries shorter than this many labels are dropped. A bare `ru` would
/// otherwise block every Russian domain, including legitimate ones — garbage
/// like that does appear in aggregated feeds.
const _minimumLabels = 2;

/// Lives in its own database file on purpose: `qorgan_messages.db` is at
/// `version: 1` with no `onUpgrade`, so adding a table there would break
/// updates for anyone who already has the app.
class SqliteBlocklist implements Blocklist {
  SqliteBlocklist({Future<String> Function()? readSeed})
    : _readSeed = readSeed ?? _loadSeedAsset;

  static Future<String> _loadSeedAsset() =>
      rootBundle.loadString(blocklistSeedAsset);

  final Future<String> Function() _readSeed;
  Future<Database>? _database;

  Future<Database> get _db => _database ??= _open();

  Future<Database> _open() async {
    final db = await openDatabase(
      paths.join(await getDatabasesPath(), 'qorgan_blocklist.db'),
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE blocked_hosts (host TEXT PRIMARY KEY) WITHOUT ROWID',
      ),
    );
    // An empty table means nothing has been loaded yet. Once an update has
    // landed the table is not empty, so the shipped seed never overwrites it.
    final rows = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM blocked_hosts'),
    );
    if (rows == 0) await _insertAll(db, parseHostList(await _readSeed()));
    return db;
  }

  static Future<void> _insertAll(Database db, Iterable<String> hosts) =>
      db.transaction((txn) async {
        final batch = txn.batch();
        for (final host in hosts) {
          batch.insert('blocked_hosts', {
            'host': host,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        await batch.commit(noResult: true);
      });

  @override
  Future<Set<String>> blockedAmong(Iterable<String> hosts) async {
    // One indexed query per message, not per host: the SMS receiver has a
    // nine-second budget and most of it is already spent starting Dart.
    final candidates = <String, String>{};
    for (final host in hosts) {
      for (final suffix in _suffixes(host)) {
        candidates[suffix] = host;
      }
    }
    if (candidates.isEmpty) return const {};

    final placeholders = List.filled(candidates.length, '?').join(', ');
    final rows = await (await _db).rawQuery(
      'SELECT host FROM blocked_hosts WHERE host IN ($placeholders)',
      candidates.keys.toList(),
    );
    return rows.map((row) => candidates[row['host'] as String]!).toSet();
  }

  /// Replaces the whole list. Used by the updater; an update is all-or-nothing
  /// so a half-applied list can never be queried.
  Future<void> replaceAll(Iterable<String> hosts) async {
    final db = await _db;
    final parsed = parseHostList(hosts.join('\n'));
    await db.transaction((txn) async {
      await txn.delete('blocked_hosts');
      final batch = txn.batch();
      for (final host in parsed) {
        batch.insert('blocked_hosts', {
          'host': host,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await batch.commit(noResult: true);
    });
  }

  Future<int> count() async =>
      Sqflite.firstIntValue(
        await (await _db).rawQuery('SELECT COUNT(*) FROM blocked_hosts'),
      ) ??
      0;
}

/// The host itself and each parent that still has enough labels to be a real
/// domain, so a blocked `evil.ru` also covers `login.evil.ru`.
Iterable<String> _suffixes(String host) {
  final labels = host.split('.');
  return [
    for (var i = 0; i <= labels.length - _minimumLabels; i++)
      labels.sublist(i).join('.'),
  ];
}

/// Parses a feed or the shipped seed: one host per line, `#` comments and
/// blank lines ignored, entries too short to be a domain dropped.
List<String> parseHostList(String source) => [
  for (final line in source.split('\n'))
    if (_hostOf(line) case final String host) host,
];

String? _hostOf(String line) {
  final value = line.trim().toLowerCase();
  if (value.isEmpty || value.startsWith('#')) return null;
  if (value.split('.').length < _minimumLabels) return null;
  if (value.contains(' ') || value.contains('/')) return null;
  return value;
}
