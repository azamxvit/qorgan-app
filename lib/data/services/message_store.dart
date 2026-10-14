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

class StoredMessage {
  const StoredMessage({
    required this.message,
    required this.verdict,
    this.notified = false,
  });
  final IncomingSms message;
  final MessageVerdict verdict;
  final bool notified;
  String get key => message.key;
  int get notificationId =>
      int.parse(key.substring(0, 8), radix: 16) & 0x7fffffff;
  StoredMessage withNotified() =>
      StoredMessage(message: message, verdict: verdict, notified: true);
  Map<String, Object?> toMap() => {
    'message_key': key,
    'sender': message.sender,
    'body': message.body,
    'received_at': message.timestamp,
    'score': verdict.score,
    'signals': jsonEncode(verdict.signals.map((s) => s.name).toList()),
    'notified': notified ? 1 : 0,
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
  );
}

abstract interface class MessageStore {
  Future<StoredMessage> save(StoredMessage record);
  Future<void> markNotified(String key);
  Future<StoredMessage?> latest();
}

class SqliteMessageStore implements MessageStore {
  Future<Database>? _database;
  Future<Database> get _db => _database ??= _open();
  Future<Database> _open() async => openDatabase(
    paths.join(await getDatabasesPath(), 'qorgan_messages.db'),
    version: 1,
    onCreate: (db, _) => db.execute(
      'CREATE TABLE messages (message_key TEXT PRIMARY KEY, sender TEXT NOT NULL, body TEXT NOT NULL, received_at INTEGER NOT NULL, score INTEGER NOT NULL, signals TEXT NOT NULL, notified INTEGER NOT NULL DEFAULT 0)',
    ),
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
