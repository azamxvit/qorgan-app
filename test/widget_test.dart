import 'package:flutter_test/flutter_test.dart';
import 'package:qorgan_app/main.dart';

void main() {
  testWidgets('opens on the background screen', (WidgetTester tester) async {
    await tester.pumpWidget(const QorganApp());
    expect(find.text('Qorğan'), findsOneWidget);
    expect(find.text('Фоновое приложение'), findsOneWidget);
  });
}
