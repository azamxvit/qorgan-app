import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/services/message_store.dart';
import 'package:qorgan_app/domain/inspect_message.dart';
import 'package:qorgan_app/ui/core/light_components.dart';
import 'package:qorgan_app/ui/core/theme.dart';
import 'package:qorgan_app/ui/messages/protection_dashboard.dart';
import 'package:qorgan_app/ui/messages/message_detail_page.dart';

void main() {
  final header = SmsHeader(onBack: () {}, onMenu: () {}, onProfile: () {});
  final sms = IncomingSms(
    sender: 'ACME VERIFICATION SERVICE',
    body: 'код',
    timestamp: 1,
  );
  final record = StoredMessage(message: sms, verdict: inspectMessage(sms.body));
  testWidgets('dashboard at 320 and large accessibility text', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: qorganTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(2)),
          child: child!,
        ),
        home: ProtectionDashboard(
          messages: [record],
          header: header,
          onMessage: (_) {},
          onAll: () {},
          onSettings: () {},
          active: false,
          supported: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('long sender detail at 320', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: qorganTheme(),
        home: SmsDetailPage(record: record, header: header, onSignals: () {}),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
