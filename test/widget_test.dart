import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/main.dart';

void main() {
  testWidgets('Piano app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PianoApp());
    expect(find.text('Piano'), findsOneWidget);
  });
}
