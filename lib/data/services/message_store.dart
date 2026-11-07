import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite/sqflite.dart';

import '../../domain/models/message_verdict.dart';

class IncomingSms {
  const IncomingSms({
    required this.sender,
    required this.body,
    required this.timestamp,
  });
  final String sender;
  final String body;
  final int timestamp;
  String get key => sha256
      .convert(utf8.encode(jsonEncode([sender, timestamp, body])))
      .toString();
}

/// What the user said about a verdict. The rule is not overridden by it: a
/// tap must not be able to whitelist an attacker. It is recorded so the
/// detector can be corrected deliberately, with the corpus as the gate.
///
/// Persisted by name, so values may only be appended and never renamed.
enum MessageFeedback {
  /// Not asked, or no opinion.
  none,

  /// "This is not fraud" — a false alarm.
  wrong,

  /// "This really is fraud" — a miss, or a confirmation.
  fraud,
}

class StoredMessage {
  const StoredMessage({
    required this.message,
    required this.verdict,
    this.notified = false,
    this.feedback = MessageFeedback.none,
  });
  final IncomingSms message;
  final MessageVerdict verdict;
  final bool notified;
  final MessageFeedback feedback;
  String get key => message.key;
  int get notificationId =>
      int.parse(key.substring(0, 8), radix: 16) & 0x7fffffff;
  StoredMessage withNotified() => StoredMessage(
    message: message,
    verdict: verdict,
    notified: true,
    feedback: feedback,
  );
  Map<String, Object?> toMap() => {
    'message_key': key,
    'sender': message.sender,
    'body': message.body,
    'received_at': message.timestamp,
    'score': verdict.score,
    'signals': jsonEncode(verdict.signals.map((s) => s.name).toList()),
    'notified': notified ? 1 : 0,
    'feedback': feedback.name,
  };
  factory StoredMessage.fromMap(Map<String, Object?> map) => StoredMessage(
    message: IncomingSms(
      sender: map['sender'] as String,
      body: map['body'] as String,
      timestamp: map['received_at'] as int,
    ),
    verdict: MessageVerdict(
      score: map['score'] as int,
      signals: (jsonDecode(map['signals'] as String) as List)
          .map((s) => MessageSignal.values.byName(s as String))
          .toList(),
    ),
    notified: map['notified'] == 1,
    // Rows written by schema version 1 have no column at all, and a value
    // written by a newer build must not crash an older one.
    feedback:
        MessageFeedback.values.asNameMap()[map['feedback']] ??
        MessageFeedback.none,
  );
}

abstract interface class MessageStore {
  Future<StoredMessage> save(StoredMessage record);
  Future<void> markNotified(String key);
  Future<StoredMessage?> latest();
}

/// Optional lookup for consumers that must detect a record deleted meanwhile.
abstract interface class StoredMessageLookup implements MessageStore {
  Future<StoredMessage?> byKey(String key);
}

/// Columns of schema version 1, kept here so the upgrade path is readable
/// next to the statement that creates version 2.
const _messagesV1 =
    'message_key TEXT PRIMARY KEY, sender TEXT NOT NULL, body TEXT NOT NULL, '
    'received_at INTEGER NOT NULL, score INTEGER NOT NULL, signals TEXT NOT '
    'NULL, notified INTEGER NOT NULL DEFAULT 0';

/// Nullable on purpose: `ALTER TABLE ... ADD COLUMN` cannot add a NOT NULL
/// column without a default, and a default would rewrite existing rows.
const _feedbackColumn = "feedback TEXT DEFAULT 'none'";

class SqliteMessageStore implements MessageStore, StoredMessageLookup {
  Future<Database>? _database;
  Future<Database> get _db => _database ??= _open();
  Future<Database> _open() async => openDatabase(
    paths.join(await getDatabasesPath(), 'qorgan_messages.db'),
    version: 2,
    onCreate: (db, _) =>
        db.execute('CREATE TABLE messages ($_messagesV1, $_feedbackColumn)'),
    // Version 1 shipped without a migration path, which meant the first
    // schema change would have broken every existing install. Adding a
    // nullable column is the safe shape: old rows keep working untouched.
    onUpgrade: (db, from, to) async {
      if (from < 2) {
        await db.execute('ALTER TABLE messages ADD COLUMN $_feedbackColumn');
      }
    },
  );
  @override
  Future<StoredMessage> save(StoredMessage record) async {
    final db = await _db;
    return db.transaction((txn) async {
      await txn.insert(
        'messages',
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
      final row = (await txn.query(
        'messages',
        where: 'message_key = ?',
        whereArgs: [record.key],
      )).single;
      await txn.rawDelete(
        'DELETE FROM messages WHERE message_key NOT IN (SELECT message_key FROM messages ORDER BY received_at DESC, rowid DESC LIMIT 100)',
      );
      return StoredMessage.fromMap(row);
    });
  }

  /// Deletes exactly the records named, and nothing else.
  ///
  /// Deleting by key rather than emptying the table is what keeps an SMS that
  /// arrives while the user is clearing: it was never in the list they saw, so
  /// it is not theirs to delete.
  Future<void> deleteKeys(Iterable<String> keys) async {
    final list = keys.toList(growable: false);
    if (list.isEmpty) return;
    final placeholders = List.filled(list.length, '?').join(', ');
    await (await _db).delete(
      'messages',
      where: 'message_key IN ($placeholders)',
      whereArgs: list,
    );
  }

  /// Deletes every stored message. The caller is telling the user their
  /// history is gone, so this has to actually delete rather than report
  /// success — the first version of this feature ended in an empty no-op and
  /// the rows stayed on the phone.
  Future<void> clearHistory() async => (await _db).delete('messages');

  /// Records what the user said. Deliberately does not touch the verdict.
  Future<void> recordFeedback(String key, MessageFeedback feedback) async {
    final changed = await (await _db).update(
      'messages',
      {'feedback': feedback.name},
      where: 'message_key = ?',
      whereArgs: [key],
    );
    if (changed != 1) {
      throw StateError('The selected message no longer exists.');
    }
  }

  @override
  Future<void> markNotified(String key) async => (await _db).update(
    'messages',
    {'notified': 1},
    where: 'message_key = ?',
    whereArgs: [key],
  );
  @override
  Future<StoredMessage?> latest() async {
    final rows = await (await _db).query(
      'messages',
      orderBy: 'received_at DESC, rowid DESC',
      limit: 1,
    );
    return rows.isEmpty ? null : StoredMessage.fromMap(rows.first);
  }

  @override
  Future<StoredMessage?> byKey(String key) async {
    final rows = await (await _db).query(
      'messages',
      where: 'message_key = ?',
      whereArgs: [key],
      limit: 1,
    );
    return rows.isEmpty ? null : StoredMessage.fromMap(rows.first);
  }

  Future<List<StoredMessage>> recent() async {
    final rows = await (await _db).query(
      'messages',
      orderBy: 'received_at DESC, rowid DESC',
      limit: 100,
    );
    return rows.map(StoredMessage.fromMap).toList(growable: false);
  }
}
