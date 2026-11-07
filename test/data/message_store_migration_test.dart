import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Exactly the schema shipped as version 1. Copied verbatim on purpose: this
/// is what is already on a user's phone, and the test must not drift with the
/// production statement.
const _version1Schema =
    'CREATE TABLE messages (message_key TEXT PRIMARY KEY, sender TEXT NOT '
    'NULL, body TEXT NOT NULL, received_at INTEGER NOT NULL, score INTEGER '
    'NOT NULL, signals TEXT NOT NULL, notified INTEGER NOT NULL DEFAULT 0)';

void main() {
  late Directory directory;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('qorgan-migration-');
    await databaseFactory.setDatabasesPath(directory.path);
  });
  tearDown(() async => directory.delete(recursive: true));

  Future<void> seedVersion1() async {
    final db = await databaseFactory.openDatabase(
      '${directory.path}/qorgan_messages.db',
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, _) => db.execute(_version1Schema),
      ),
    );
    await db.insert('messages', {
      'message_key': 'already-stored',
      'sender': 'KASPI',
      'body': 'Kaspi.kz: код 8123 для входа',
      'received_at': 1000,
      'score': 1,
      'signals': jsonEncode(['bank']),
      'notified': 0,
    });
    await db.close();
  }

  test('a database written by version 1 survives the upgrade', () async {
    await seedVersion1();

    final restored = await SqliteMessageStore().byKey('already-stored');

    expect(restored, isNotNull);
    expect(restored!.message.sender, 'KASPI');
    expect(restored.feedback, MessageFeedback.none);
  });

  test('feedback recorded after the upgrade is read back', () async {
    await seedVersion1();
    final store = SqliteMessageStore();

    await store.recordFeedback('already-stored', MessageFeedback.wrong);

    expect(
      (await store.byKey('already-stored'))?.feedback,
      MessageFeedback.wrong,
    );
  });
}
