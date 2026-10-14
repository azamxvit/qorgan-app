import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/domain/inspect_message.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory directory;
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('qorgan-sqlite-');
    await databaseFactory.setDatabasesPath(directory.path);
  });
  tearDown(() async {
    final db = await databaseFactory.openDatabase(
      '${directory.path}/qorgan_messages.db',
    );
    await db.close();
    await directory.delete(recursive: true);
  });
  StoredMessage record(int time) {
    final sms = IncomingSms(
      sender: 'Bank',
      body: 'Срочно сообщите код $time',
      timestamp: time,
    );
    return StoredMessage(message: sms, verdict: inspectMessage(sms.body));
  }

  test('a new store restores the saved verdict and notified status', () async {
    final store = SqliteMessageStore();
    final incoming = record(1);
    await store.save(incoming);
    await store.markNotified(incoming.key);
    final restored = await SqliteMessageStore().latest();
    expect(restored?.message.body, 'Срочно сообщите код 1');
    expect(restored?.verdict.score, 5);
    expect(restored?.notified, isTrue);
    expect((await store.save(incoming)).notified, isTrue);
  });
  test(
    'recent history is newest first and excludes redelivery duplicates',
    () async {
      final store = SqliteMessageStore();
      await store.save(record(10));
      await store.save(record(30));
      await store.save(record(20));
      await store.save(record(30));
      final rows = await store.recent();
      expect(rows.map((row) => row.message.timestamp), [30, 20, 10]);
    },
  );
  test('retention keeps only the last 100 SMS and tap lookup finds older kept message', () async {
    final store = SqliteMessageStore();
    for (var i = 0; i < 105; i++) {
      await store.save(record(i));
    }
    expect(await store.byKey(record(4).key), isNull);
    expect((await store.byKey(record(5).key))?.message.timestamp, 5);
    expect((await store.latest())?.message.timestamp, 104);
    final db = await databaseFactory.openDatabase(
      '${directory.path}/qorgan_messages.db',
    );
    final count = await db.rawQuery('SELECT COUNT(*) AS n FROM messages');
    expect(count.single['n'], 100);
  });
}
