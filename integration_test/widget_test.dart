import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rockit/main.dart';

Future<void> main() async {
  final binding = IntegrationTestWidgetsFlutterBinding();
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets("The app starts", (WidgetTester tester) async {
    await tester.pumpWidget(const RockItApp(disableBanner: true));

    // Find the app bar text
    expect(find.text('Rock It!'), findsOneWidget);

    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('test-screenshot');
  });
}
