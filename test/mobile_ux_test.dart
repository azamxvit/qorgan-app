import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/repositories/protection_repository.dart';
import 'package:qorgan_app/data/services/incoming_message_service.dart';
import 'package:qorgan_app/ui/qorgan_app.dart';
import 'package:qorgan_app/data/services/onboarding_settings.dart';
import 'package:qorgan_app/data/services/protection_settings.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/domain/models/message_verdict.dart';

class FreshPhone extends UnboundIncomingMessageService {
  int requests = 0;
  int smsRequests = 0;
  int notificationRequests = 0;
  bool sms = false;
  bool notifications = false;
  bool grantSms = true;
  bool failStatus = false;
  bool selected = false;
  @override
  bool get hasNotificationSelection => selected;
  @override
  Future<ProtectionAccess> status() async {
    if (failStatus) throw StateError('unavailable');
    return ProtectionAccess(
      supported: true,
      sms: sms,
      notifications: notifications,
    );
  }

  @override
  Future<ProtectionAccess> requestAccess() async {
    requests++;
    return status();
  }

  @override
  Future<ProtectionAccess> requestSmsAccess() async {
    smsRequests++;
    sms = grantSms;
    return status();
  }

  @override
  Future<ProtectionAccess> requestNotificationAccess() async {
    notificationRequests++;
    notifications = true;
    return status();
  }
}

void main() {
  testWidgets(
    'first launch offers manual check without permission or account',
    (tester) async {
      final phone = FreshPhone();
      await tester.pumpWidget(
        QorganApp(repository: ProtectionRepository(), incomingMessages: phone),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('welcome')), findsOneWidget);
      expect(find.text('Настроить защиту'), findsOneWidget);
      expect(find.text('Войти'), findsNothing);
      await tester.ensureVisible(find.text('Проверить SMS вручную'));
      await tester.tap(find.text('Проверить SMS вручную'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(
        phone.requests + phone.smsRequests + phone.notificationRequests,
        0,
      );
    },
  );

  testWidgets('root tabs preserve the manual draft and do not stack routes', (
    tester,
  ) async {
    await tester.pumpWidget(
      QorganApp(
        repository: ProtectionRepository(),
        incomingMessages: FreshPhone(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Проверить SMS вручную'));
    await tester.tap(find.text('Проверить SMS вручную'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Мой текст');
    await tester.tap(find.byKey(const ValueKey('tab-messages')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-check')));
    await tester.pumpAndSettle();
    expect(find.text('Мой текст'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('tab-check')));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'setup requests separately and enables only after explicit action',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final phone = FreshPhone();
      final repository = ProtectionRepository();
      await tester.pumpWidget(
        QorganApp(repository: repository, incomingMessages: phone),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Настроить защиту'));
      await tester.tap(find.text('Настроить защиту'));
      await tester.pumpAndSettle();
      expect(phone.smsRequests, 0);
      await tester.tap(find.text('Разрешить приём SMS'));
      await tester.pumpAndSettle();
      expect(find.text('Доступ к новым SMS'), findsOneWidget);
      expect(phone.smsRequests, 0);
      expect(repository.armed, isFalse);
      await tester.scrollUntilVisible(
        find.text('Согласен, разрешить приём SMS'),
        200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Согласен, разрешить приём SMS'));
      await tester.pumpAndSettle();
      expect(phone.smsRequests, 1);
      expect(phone.notificationRequests, 0);
      expect(repository.armed, isFalse);
      await tester.ensureVisible(find.text('Разрешить уведомления'));
      await tester.tap(find.text('Разрешить уведомления'));
      await tester.pumpAndSettle();
      expect(phone.notificationRequests, 1);
      expect(repository.armed, isFalse);
      await tester.ensureVisible(find.text('Включить защиту'));
      await tester.tap(find.text('Включить защиту'));
      await tester.pumpAndSettle();
      expect(repository.armed, isTrue);
      expect(find.text('Проверка новых SMS включена'), findsWidgets);
    },
  );

  testWidgets('denied SMS access does not request alerts or trap user', (
    tester,
  ) async {
    final phone = FreshPhone()..grantSms = false;
    await tester.pumpWidget(
      QorganApp(repository: ProtectionRepository(), incomingMessages: phone),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Настроить защиту'));
    await tester.tap(find.text('Настроить защиту'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Разрешить приём SMS'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Согласен, разрешить приём SMS'),
      200,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Согласен, разрешить приём SMS'));
    await tester.pumpAndSettle();
    expect(phone.smsRequests, 1);
    await tester.scrollUntilVisible(
      find.textContaining('Доступ к новым SMS не предоставлен'),
      150,
    );
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Доступ к новым SMS не предоставлен'),
      findsOneWidget,
    );
    expect(phone.notificationRequests, 0);
    await tester.scrollUntilVisible(find.text('Позже'), 200);
    await tester.tap(find.text('Позже'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('tab-check')));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });

  for (final exit in [
    'decline',
    'header back',
    'system back',
    'privacy back',
  ]) {
    testWidgets(
      'disclosure $exit never requests access or enables protection',
      (tester) async {
        final phone = FreshPhone();
        final repository = ProtectionRepository();
        await tester.pumpWidget(
          QorganApp(repository: repository, incomingMessages: phone),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Настроить защиту'));
        await tester.tap(find.text('Настроить защиту'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Разрешить приём SMS'));
        await tester.pumpAndSettle();
        expect(find.text('Доступ к новым SMS'), findsOneWidget);
        if (exit == 'privacy back') {
          await tester.scrollUntilVisible(
            find.text('Политика конфиденциальности'),
            200,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.text('Политика конфиденциальности'));
          await tester.pumpAndSettle();
          expect(find.text('Политика конфиденциальности'), findsOneWidget);
          expect(phone.smsRequests, 0);
          await tester.tap(find.byTooltip('Назад'));
          await tester.pumpAndSettle();
          expect(find.text('Согласен, разрешить приём SMS'), findsOneWidget);
          expect(phone.smsRequests, 0);
        }
        if (exit == 'decline') {
          await tester.scrollUntilVisible(find.text('Не сейчас'), 200);
          await tester.pumpAndSettle();
          await tester.tap(find.text('Не сейчас'));
        } else if (exit == 'header back') {
          await tester.tap(find.byTooltip('Назад'));
        } else {
          await tester.binding.handlePopRoute();
        }
        await tester.pumpAndSettle();
        expect(find.text('Настройте защиту'), findsOneWidget);
        expect(
          phone.smsRequests + phone.notificationRequests + phone.requests,
          0,
        );
        expect(repository.armed, isFalse);
        // Reopening must ask again; leaving is never remembered as consent.
        await tester.ensureVisible(find.text('Разрешить приём SMS'));
        await tester.tap(find.text('Разрешить приём SMS'));
        await tester.pumpAndSettle();
        expect(find.text('Доступ к новым SMS'), findsOneWidget);
        expect(phone.smsRequests, 0);
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Позже'), 200);
        await tester.tap(find.text('Позже'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('tab-check')));
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsOneWidget);
        expect(
          phone.smsRequests + phone.notificationRequests + phone.requests,
          0,
        );
        expect(repository.armed, isFalse);
      },
    );
  }

  testWidgets('notification replacing disclosure cannot grant consent', (
    tester,
  ) async {
    final phone = FreshPhone();
    final repository = ProtectionRepository();
    await tester.pumpWidget(
      QorganApp(repository: repository, incomingMessages: phone),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Настроить защиту'));
    await tester.tap(find.text('Настроить защиту'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Разрешить приём SMS'));
    await tester.pumpAndSettle();
    expect(find.text('Доступ к новым SMS'), findsOneWidget);
    phone.onOpenMessage!();
    await tester.pumpAndSettle();
    expect(find.text('Сообщение больше не хранится в Qorğan'), findsOneWidget);
    expect(phone.smsRequests + phone.notificationRequests + phone.requests, 0);
    expect(repository.armed, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disclosure is readable and actionable at 320px and 200% text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    final semantics = tester.ensureSemantics();
    try {
      final phone = FreshPhone();
      final repository = ProtectionRepository();
      await tester.pumpWidget(
        QorganApp(repository: repository, incomingMessages: phone),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Настроить защиту'));
      await tester.tap(find.text('Настроить защиту'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Разрешить приём SMS'), 150);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Разрешить приём SMS'));
      await tester.pumpAndSettle();
      for (final fact in [
        'текст и отправителя новых входящих SMS',
        'когда приложение не открыто',
        'последние 100 принятых SMS',
        'не отправляет автоматически',
        'Старую переписку',
        'Ручная проверка доступна без разрешения',
      ]) {
        await tester.scrollUntilVisible(find.textContaining(fact), 150);
        await tester.pumpAndSettle();
        expect(find.textContaining(fact), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.scrollUntilVisible(
        find.text('Согласен, разрешить приём SMS'),
        150,
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSemantics(find.text('Согласен, разрешить приём SMS')),
        matchesSemantics(
          label: 'Согласен, разрешить приём SMS',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );
      expect(phone.smsRequests, 0);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Согласен, разрешить приём SMS'));
      await tester.pumpAndSettle();
      expect(phone.smsRequests, 1);
      expect(repository.armed, isFalse);
      expect(tester.takeException(), isNull);
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('saved false setting migrates existing user without welcome', (
    tester,
  ) async {
    await tester.pumpWidget(
      QorganApp(
        repository: ProtectionRepository(
          settings: MemoryProtectionSettings(armed: false),
        ),
        incomingMessages: FreshPhone(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('welcome')), findsNothing);
    expect(find.text('Автопроверка выключена'), findsOneWidget);
  });

  testWidgets('manual choice persists through relaunch', (tester) async {
    final onboarding = MemoryOnboardingSettings();
    Future<void> open() => tester.pumpWidget(
      QorganApp(
        onboarding: onboarding,
        repository: ProtectionRepository(),
        incomingMessages: FreshPhone(),
      ),
    );
    await open();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Проверить SMS вручную'));
    await tester.tap(find.text('Проверить SMS вручную'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await open();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('welcome')), findsNothing);
    expect(find.text('Автопроверка выключена'), findsOneWidget);
  });

  testWidgets('unavailable status is not reported as disabled or active', (
    tester,
  ) async {
    await tester.pumpWidget(
      QorganApp(
        onboarding: MemoryOnboardingSettings(completed: true),
        repository: ProtectionRepository(),
        incomingMessages: FreshPhone()..failStatus = true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Не удалось проверить состояние'), findsOneWidget);
    expect(find.text('Автопроверка выключена'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('tab-check')));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('revoked notifications show partial readiness after resume', (
    tester,
  ) async {
    final phone = FreshPhone()
      ..sms = true
      ..notifications = true;
    await tester.pumpWidget(
      QorganApp(
        repository: ProtectionRepository(
          settings: MemoryProtectionSettings(armed: true),
        ),
        incomingMessages: phone,
      ),
    );
    await tester.pumpAndSettle();
    phone.notifications = false;
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pumpAndSettle();
    expect(find.text('Предупреждения выключены'), findsOneWidget);
    expect(
      find.text('Включите проверку новых SMS или проверьте текст вручную.'),
      findsNothing,
    );
    expect(find.text('Автопроверка выключена'), findsNothing);
  });

  testWidgets('missing notification record never opens another latest SMS', (
    tester,
  ) async {
    await tester.pumpWidget(
      QorganApp(
        repository: ProtectionRepository(),
        incomingMessages: MissingNotification(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Сообщение больше не хранится в Qorğan'), findsOneWidget);
    expect(find.byKey(const ValueKey('welcome')), findsNothing);
    expect(find.text('Текст SMS'), findsNothing);
    await tester.tap(find.text('К сообщениям'));
    await tester.pumpAndSettle();
    expect(find.text('Different sender'), findsOneWidget);
  });

  testWidgets(
    'history clear is confirmed and keeps the protection preference',
    (tester) async {
      final phone = ClearablePhone();
      final repository = ProtectionRepository(
        settings: MemoryProtectionSettings(armed: true),
      );
      phone.sms = true;
      phone.notifications = true;
      await tester.pumpWidget(
        QorganApp(repository: repository, incomingMessages: phone),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Настройки'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('Очистить историю'), 200);
      await tester.tap(find.text('Очистить историю'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(phone.records, isNotEmpty);
      await tester.tap(find.text('Очистить историю'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Удалить историю'));
      await tester.pumpAndSettle();
      expect(phone.records, isEmpty);
      expect(repository.armed, isTrue);
      expect(find.text('Очистить историю'), findsNothing);
    },
  );

  testWidgets('welcome and roots remain usable at 320px and 200 percent text', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(() {
      tester.binding.setSurfaceSize(null);
      tester.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await tester.pumpWidget(
      QorganApp(
        repository: ProtectionRepository(),
        incomingMessages: FreshPhone(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Проверить SMS вручную'));
    await tester.tap(find.text('Проверить SMS вручную'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('tab-protection')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('tab-messages')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

class MissingNotification extends FreshPhone {
  MissingNotification() {
    selected = true;
  }
  final record = const StoredMessage(
    message: IncomingSms(
      sender: 'Different sender',
      body: 'Different message',
      timestamp: 1,
    ),
    verdict: MessageVerdict.clear,
  );
  @override
  Future<List<StoredMessage>> recent() async => [record];
  @override
  Future<StoredMessage?> latest() async => record;
}

class ClearablePhone extends FreshPhone {
  List<StoredMessage> records = [
    const StoredMessage(
      message: IncomingSms(
        sender: 'Stored sender',
        body: 'Stored message',
        timestamp: 1,
      ),
      verdict: MessageVerdict.clear,
    ),
  ];
  @override
  Future<List<StoredMessage>> recent() async => List.of(records);
  @override
  Future<void> clearHistory() async => records.clear();
}
