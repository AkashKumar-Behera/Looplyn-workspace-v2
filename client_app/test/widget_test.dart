import 'package:flutter_test/flutter_test.dart';
import 'package:client_app/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LooplynApp());
    expect(find.text('Looplyn'), findsOneWidget);
  });
}
