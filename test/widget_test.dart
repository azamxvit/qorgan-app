import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/data/repositories/protection_repository.dart';
import 'package:qorgan_app/data/services/incoming_message_service.dart';
import 'package:qorgan_app/ui/qorgan_app.dart';

void main() {
  testWidgets('opens on background protection without a remote module', (
    tester,
  ) async {
    await tester.pumpWidget(
      QorganApp(
        repository: ProtectionRepository(),
        incomingMessages: UnboundIncomingMessageService(),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Защита'), findsNWidgets(2));
    expect(find.text('Последние SMS'), findsOneWidget);
    expect(find.text('AI Analyze'), findsNothing);
    expect(find.textContaining('manus'), findsNothing);
  });
}
