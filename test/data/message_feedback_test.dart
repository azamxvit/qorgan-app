import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/services/android_sms_service.dart';
import 'package:qorgan_app/data/services/blocklist_store.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/data/services/protection_settings.dart';
import 'package:qorgan_app/domain/inspect_message.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../domain/sms_corpus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('qorgan-feedback-');
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
      sender: legitimateSms.first.sender,
      body: legitimateSms.first.body,
      timestamp: time,
    );
    return StoredMessage(message: sms, verdict: inspectMessage(sms.body));
  }

  test(
    'missing or deleted SMS feedback never reports a successful write',
    () async {
      final store = SqliteMessageStore();
      await expectLater(
        store.recordFeedback('missing', MessageFeedback.fraud),
        throwsStateError,
      );
      final saved = await store.save(record(1));
      await store.deleteKeys([saved.key]);
      await expectLater(
        store.recordFeedback(saved.key, MessageFeedback.wrong),
        throwsStateError,
      );
      expect(await store.recent(), isEmpty);
    },
  );

  test(
    'production Android service persists only the selected record feedback',
    () async {
      final store = SqliteMessageStore();
      final selected = await store.save(record(1));
      final other = await store.save(record(2));
      final service = AndroidSmsService(
        settings: MemoryProtectionSettings(),
        blocklist: const EmptyBlocklist(),
        store: store,
      );
      await service.recordFeedback(selected.key, MessageFeedback.wrong);
      final restored = await SqliteMessageStore().byKey(selected.key);
      expect(restored?.feedback, MessageFeedback.wrong);
      expect(restored?.verdict.score, selected.verdict.score);
      expect(restored?.message.body, selected.message.body);
      expect((await store.byKey(other.key))?.feedback, MessageFeedback.none);
      await store.deleteKeys([selected.key]);
      await expectLater(
        service.recordFeedback(selected.key, MessageFeedback.fraud),
        throwsStateError,
      );
    },
  );
}
