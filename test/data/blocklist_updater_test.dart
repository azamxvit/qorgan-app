import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/services/blocklist_store.dart';
import 'package:qorgan_app/data/services/blocklist_updater.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Enough hosts to clear the updater's plausibility floor.
String feedOf(int count, {String prefix = 'host'}) =>
    List.generate(count, (i) => '$prefix$i.example').join('\n');

void main() {
  late Directory directory;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('qorgan-updater-');
    await databaseFactory.setDatabasesPath(directory.path);
  });
  tearDown(() async => directory.delete(recursive: true));

  SqliteBlocklist freshStore() =>
      SqliteBlocklist(readSeed: () async => feedOf(1200, prefix: 'seed'));

  test('a fetched list replaces the seed', () async {
    final store = freshStore();
    final asked = <Uri>[];
    final updater = BlocklistUpdater(
      store: store,
      source: Uri.parse('https://example.org/hosts.txt'),
      fetch: (uri) async {
        asked.add(uri);
        return feedOf(1200, prefix: 'fresh');
      },
    );

    final outcome = await updater.update(now: DateTime(2026, 11, 7));

    expect(outcome, BlocklistUpdate.applied);
    expect(await store.blockedAmong(['fresh7.example']), {'fresh7.example'});
    expect(await store.blockedAmong(['seed7.example']), isEmpty);
    expect(asked, [Uri.parse('https://example.org/hosts.txt')]);
  });

  test('plain http is refused without being fetched', () async {
    var fetched = false;
    final updater = BlocklistUpdater(
      store: freshStore(),
      source: Uri.parse('http://example.org/hosts.txt'),
      fetch: (uri) async {
        fetched = true;
        return feedOf(1200);
      },
    );

    expect(
      () => updater.update(now: DateTime(2026, 11, 7)),
      throwsA(isA<ArgumentError>()),
    );
    expect(fetched, isFalse);
  });

  test('an implausibly short list is rejected and the old one kept', () async {
    final store = freshStore();
    final updater = BlocklistUpdater(
      store: store,
      source: Uri.parse('https://example.org/hosts.txt'),
      // A truncated or hostile response that silently disables protection is
      // the failure mode that matters: nothing visibly breaks.
      fetch: (uri) async => 'evil.ru\n',
    );

    final outcome = await updater.update(now: DateTime(2026, 11, 7));

    expect(outcome, BlocklistUpdate.rejected);
    expect(await store.blockedAmong(['seed7.example']), {'seed7.example'});
  });

  test('a checksum mismatch is rejected and the old list kept', () async {
    final store = freshStore();
    final updater = BlocklistUpdater(
      store: store,
      source: Uri.parse('https://example.org/hosts.txt'),
      fetch: (uri) async => feedOf(1200, prefix: 'fresh'),
      expectedSha256: 'not-the-digest-of-this-body',
    );

    final outcome = await updater.update(now: DateTime(2026, 11, 7));

    expect(outcome, BlocklistUpdate.rejected);
    expect(await store.blockedAmong(['seed7.example']), {'seed7.example'});
  });

  test('a second update inside the interval does not refetch', () async {
    final store = freshStore();
    var calls = 0;
    final updater = BlocklistUpdater(
      store: store,
      source: Uri.parse('https://example.org/hosts.txt'),
      fetch: (uri) async {
        calls += 1;
        return feedOf(1200, prefix: 'fresh');
      },
    );

    await updater.update(now: DateTime(2026, 11, 7, 9));
    final second = await updater.update(now: DateTime(2026, 11, 7, 12));

    expect(second, BlocklistUpdate.tooSoon);
    expect(calls, 1);
  });

  test('the interval expires and the next update refetches', () async {
    final store = freshStore();
    var calls = 0;
    final updater = BlocklistUpdater(
      store: store,
      source: Uri.parse('https://example.org/hosts.txt'),
      fetch: (uri) async {
        calls += 1;
        return feedOf(1200, prefix: 'fresh');
      },
    );

    await updater.update(now: DateTime(2026, 11, 7, 9));
    final later = await updater.update(now: DateTime(2026, 11, 8, 9));

    expect(later, BlocklistUpdate.applied);
    expect(calls, 2);
  });

  test('a network failure leaves the previous list in place', () async {
    final store = freshStore();
    final updater = BlocklistUpdater(
      store: store,
      source: Uri.parse('https://example.org/hosts.txt'),
      fetch: (uri) async => throw const SocketException('offline'),
    );

    final outcome = await updater.update(now: DateTime(2026, 11, 7));

    expect(outcome, BlocklistUpdate.failed);
    expect(await store.blockedAmong(['seed7.example']), {'seed7.example'});
  });

  test('the request carries nothing but the list URL', () async {
    // The privacy promise: fetching the list must not describe the user. No
    // query string, no fragment, no per-device path.
    final updater = BlocklistUpdater(
      store: freshStore(),
      source: Uri.parse('https://example.org/hosts.txt'),
      fetch: (uri) async {
        expect(uri.query, isEmpty);
        expect(uri.fragment, isEmpty);
        return feedOf(1200, prefix: 'fresh');
      },
    );

    expect(
      await updater.update(now: DateTime(2026, 11, 7)),
      BlocklistUpdate.applied,
    );
  });
}
