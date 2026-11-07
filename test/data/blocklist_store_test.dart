import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/services/blocklist_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory directory;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('qorgan-blocklist-');
    await databaseFactory.setDatabasesPath(directory.path);
  });
  tearDown(() async => directory.delete(recursive: true));

  SqliteBlocklist store({String seed = ''}) =>
      SqliteBlocklist(readSeed: () async => seed);

  test(
    'a seeded host is reported for the message host that names it',
    () async {
      final blocklist = store(seed: 'kaspi-bonus.top\nhalyk-secure.ru\n');

      expect(await blocklist.blockedAmong(['kaspi-bonus.top']), {
        'kaspi-bonus.top',
      });
      expect(await blocklist.blockedAmong(['olx.kz']), isEmpty);
    },
  );

  test('a subdomain of a blocked host counts as blocked', () async {
    final blocklist = store(seed: 'evil.ru\n');

    // The rule compares message hosts exactly, so the store has to answer
    // with the host as it appeared in the message.
    expect(await blocklist.blockedAmong(['login.evil.ru']), {'login.evil.ru'});
  });

  test('a bare suffix never matches everything under it', () async {
    final blocklist = store(seed: 'ru\nkz\n');

    expect(await blocklist.blockedAmong(['halykbank.kz']), isEmpty);
  });

  test('comments and blank lines in the seed are ignored', () async {
    final blocklist = store(seed: '# source: urlhaus\n\n  evil.ru  \n');

    expect(await blocklist.count(), 1);
    expect(await blocklist.blockedAmong(['evil.ru']), {'evil.ru'});
  });

  test('an update replaces the previous list instead of growing it', () async {
    final blocklist = store(seed: 'old.ru\n');
    expect(await blocklist.blockedAmong(['old.ru']), {'old.ru'});

    await blocklist.replaceAll(['fresh.ru']);

    expect(await blocklist.blockedAmong(['old.ru']), isEmpty);
    expect(await blocklist.blockedAmong(['fresh.ru']), {'fresh.ru'});
    expect(await blocklist.count(), 1);
  });

  test('the seed is not reloaded over an updated list', () async {
    final blocklist = store(seed: 'old.ru\n');
    await blocklist.replaceAll(['fresh.ru']);

    final reopened = SqliteBlocklist(readSeed: () async => 'old.ru\n');

    expect(await reopened.blockedAmong(['old.ru']), isEmpty);
    expect(await reopened.blockedAmong(['fresh.ru']), {'fresh.ru'});
  });
}
