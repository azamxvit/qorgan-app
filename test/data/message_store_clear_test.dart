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
    directory = await Directory.systemTemp.createTemp('qorgan-clear-');
    await databaseFactory.setDatabasesPath(directory.path);
  });
  tearDown(() async => directory.delete(recursive: true));

  StoredMessage record(int at) {
    final sms = IncomingSms(
      sender: 'KASPI',
      body: 'сообщение $at',
      timestamp: at,
    );
    return StoredMessage(message: sms, verdict: inspectMessage(sms.body));
  }

  test('clearing removes every stored message from the database', () async {
    final store = SqliteMessageStore();
    await store.save(record(1));
    await store.save(record(2));
    expect((await store.recent()).length, 2);

    await store.clearHistory();

    expect(await store.recent(), isEmpty);
    expect(await store.latest(), isNull);
  });

  test(
    'a cleared history really is gone after reopening the database',
    () async {
      final store = SqliteMessageStore();
      await store.save(record(1));
      await store.clearHistory();

      // The defect this guards against reported success while leaving the rows
      // in place; they reappeared on the next launch.
      expect(await SqliteMessageStore().recent(), isEmpty);
    },
  );

  test('clearing does not break the store for new messages', () async {
    final store = SqliteMessageStore();
    await store.save(record(1));
    await store.clearHistory();

    await store.save(record(3));

    expect((await store.recent()).single.message.timestamp, 3);
  });

  test('deleting by key leaves everything else alone', () async {
    final store = SqliteMessageStore();
    await store.save(record(1));
    await store.save(record(2));

    await store.deleteKeys([record(1).key]);

    expect((await store.recent()).single.message.timestamp, 2);
  });

  test('a message saved after the keys were collected survives deletion', () async {
    // Why deleting by key beats deleting everything: an SMS that arrives while
    // the user is clearing must not disappear with the records they saw.
    final store = SqliteMessageStore();
    await store.save(record(1));
    final shown = (await store.recent()).map((r) => r.key).toList();
    await store.save(record(2));

    await store.deleteKeys(shown);

    expect((await store.recent()).single.message.timestamp, 2);
  });

  test('deleting an unknown key is not an error', () async {
    final store = SqliteMessageStore();
    await store.save(record(1));

    await store.deleteKeys(['never-stored']);

    expect((await store.recent()).length, 1);
  });
}
