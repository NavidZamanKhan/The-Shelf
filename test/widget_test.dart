import 'package:flutter_test/flutter_test.dart';
import 'package:the_shelf/main.dart';
import 'package:the_shelf/screens/home_screen.dart';

void main() {
  testWidgets('App loads home screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TheShelfApp());

    // Verify that the HomeScreen is rendered.
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}
