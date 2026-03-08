import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secretlens/main.dart';

void main() {
  testWidgets('CommitBlockedScreen renders smoke test',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SecretLensApp()),
    );
    expect(find.text('COMMIT\nBLOCKED'), findsOneWidget);
  });
}
