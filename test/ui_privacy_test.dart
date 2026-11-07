import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/ui/core/light_components.dart';
import 'package:qorgan_app/ui/core/theme.dart';
import 'package:qorgan_app/ui/guard/widgets/settings_page.dart';

Future<void> openPolicy(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(320, 640));
  tester.platformDispatcher.textScaleFactorTestValue = 2;
  addTearDown(() {
    tester.binding.setSurfaceSize(null);
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
  await tester.pumpWidget(
    MaterialApp(
      theme: qorganTheme(),
      home: LocalInfoPage(
        header: SmsHeader(onBack: () {}, onMenu: () {}, onProfile: () {}),
        privacy: true,
        supported: true,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('full privacy policy remains readable without SMS permission', (
    tester,
  ) async {
    await openPolicy(tester);
    expect(find.text('Политика конфиденциальности'), findsOneWidget);
    // These are the user-visible disclosures, not a claim that the widget
    // verifies storage/network behavior (covered by the data-layer tests).
    for (final facts in [
      [
        'текст, отправителя и время получения новых SMS',
        'на вашем устройстве',
        'без разрешения на SMS',
      ],
      ['когда приложение не открыто', 'отозвать разрешение'],
      ['последние 100 принятых SMS', 'самые старые записи'],
      ['Очистить историю', 'не удаляет SMS из приложения сообщений'],
      ['оперативной памяти', 'не сохраняются в историю'],
      ['Отметки об ошибках', 'полный текст SMS', 'только по вашему действию'],
      [
        'При запуске приложение',
        'HTTPS',
        'malware-filter.gitlab.io',
        'идентификаторы устройства',
      ],
      [
        'IP-адрес',
        'GitLab Pages записывает',
        'время запроса',
        'адрес посещённой страницы',
        'Согласно опубликованной политике GitLab',
        'https://about.gitlab.com/privacy/',
        '7 дней',
        'удаляются по мере поступления новых записей',
        'срок, заявленный провайдером',
        'не управляет журналами',
        'идентификаторы устройства не добавляются в запрос',
        'автоматически не передаются',
      ],
      ['Рекламы и аналитики нет', 'Аккаунт не нужен'],
      ['Резервное копирование', 'локальные данные удаляются'],
    ]) {
      await tester.scrollUntilVisible(
        find.textContaining(facts.first),
        200,
        maxScrolls: 100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      final paragraph = tester.widget<Text>(find.textContaining(facts.first));
      for (final fact in facts) {
        expect(paragraph.data, contains(fact));
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('only supplied owner details appear as selectable text', (
    tester,
  ) async {
    await openPolicy(tester);
    // Run with defaults, empty defines and test-only --dart-define values to
    // check the actual compile-time configuration -> visible text boundary.
    const developer = String.fromEnvironment(
      'QORGAN_DEVELOPER_NAME',
      defaultValue: 'Azamat',
    );
    const support = String.fromEnvironment(
      'QORGAN_SUPPORT_EMAIL',
      defaultValue: 'omirtayazamatt@gmail.com',
    );
    const policy = String.fromEnvironment(
      'QORGAN_PRIVACY_URL',
      defaultValue: 'https://qorgan-web.vercel.app/privacy',
    );
    final supplied = {
      'Разработчик': developer.trim(),
      'Связь по вопросам конфиденциальности': support.trim(),
      'Политика на сайте': policy.trim(),
    };
    if (supplied.values.every((value) => value.isEmpty)) {
      await tester.scrollUntilVisible(
        find.text('Удаление приложения'),
        200,
        maxScrolls: 100,
      );
      await tester.pumpAndSettle();
    }
    for (final entry in supplied.entries) {
      if (entry.value.isEmpty) {
        expect(find.text(entry.key), findsNothing);
      } else {
        final value = find.byWidgetPredicate(
          (widget) => widget is SelectableText && widget.data == entry.value,
        );
        await tester.scrollUntilVisible(
          value,
          200,
          maxScrolls: 100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(value, findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
