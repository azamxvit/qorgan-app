import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/repositories/protection_repository.dart';
import 'package:qorgan_app/data/services/protection_settings.dart';
import 'package:qorgan_app/ui/core/light_components.dart';
import 'package:qorgan_app/ui/core/theme.dart';
import 'package:qorgan_app/ui/guard/view_models/guard_view_model.dart';
import 'package:qorgan_app/ui/guard/widgets/setup_page.dart';

import 'package:qorgan_app/data/services/incoming_message_service.dart';

class ReadyPhone extends UnboundIncomingMessageService {
  @override
  Future<ProtectionAccess> status() async =>
      const ProtectionAccess(supported: true, sms: true, notifications: true);
}

class SlowEnableSettings extends MemoryProtectionSettings {
  final saving = Completer<void>();
  final finish = Completer<void>();
  @override
  Future<void> writeArmed(bool value) async {
    saving.complete();
    await finish.future;
    await super.writeArmed(value);
  }
}

void main() {
  for (final replacement in [false, true]) {
    testWidgets(
      'finishing enable after leaving setup does not navigate again (notification: $replacement)',
      (tester) async {
        final settings = SlowEnableSettings();
        final phone = ReadyPhone();
        final vm = GuardViewModel(
          repository: ProtectionRepository(settings: settings),
          incomingMessages: phone,
        );
        addTearDown(vm.dispose);
        await vm.refresh();
        var completions = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: qorganTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (context) => SetupPage(
                        viewModel: vm,
                        header: SmsHeader(
                          onBack: () => Navigator.pop(context),
                          onMenu: () {},
                          onProfile: () {},
                        ),
                        onDone: () => completions++,
                        onLater: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  child: const Text('Open setup'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Open setup'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Включить защиту'));
        await tester.tap(find.text('Включить защиту'));
        await tester.pump();
        expect(settings.saving.isCompleted, isTrue);
        final navigator = Navigator.of(tester.element(find.byType(SetupPage)));
        navigator.pop();
        if (replacement) {
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) =>
                  const Scaffold(body: Text('Notification message')),
            ),
          );
          await tester.pump(const Duration(milliseconds: 10));
        } else {
          await tester.pumpAndSettle();
        }
        settings.finish.complete();
        await tester.pumpAndSettle();
        expect(completions, 0);
        expect(
          find.text(replacement ? 'Notification message' : 'Open setup'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
