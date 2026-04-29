import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_chat_app/app/app.dart';
import 'package:flutter_chat_app/app/app.locator.dart';

void main() {
  testWidgets('shows auth token hint when session is not provided', (WidgetTester tester) async {
    await setupLocator();
    await tester.pumpWidget(const ChatApp());
    await tester.pumpAndSettle();

    expect(find.text('Missing auth token'), findsOneWidget);
  });
}
