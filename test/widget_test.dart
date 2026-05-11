import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wesynk/app.dart';

void main() {
  testWidgets('WeSync app renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: WesynkApp()),
    );
    expect(find.text('WeSync'), findsOneWidget);
  });
}
