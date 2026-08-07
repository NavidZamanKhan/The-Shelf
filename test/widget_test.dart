import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_event.dart';
import 'package:the_shelf/main.dart';
import 'package:the_shelf/screens/home_screen.dart';
import 'package:the_shelf/screens/shelf_detail_screen.dart';
import 'package:the_shelf/widgets/shelf_card.dart';

void main() {
  testWidgets('App loads home screen smoke test and displays ShelfCards', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ShelfCard), findsWidgets);
  });

  testWidgets('Tapping a ShelfCard navigates to ShelfDetailScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pumpAndSettle();

    // Find and tap the Science Fiction shelf card
    final scifiCard = find.widgetWithText(ShelfCard, 'Science Fiction');
    expect(scifiCard, findsOneWidget);

    await tester.tap(scifiCard);
    await tester.pumpAndSettle();

    // Verify detail screen is displayed
    expect(find.byType(ShelfDetailScreen), findsOneWidget);
    expect(find.text('Science Fiction'), findsWidgets);
  });

  testWidgets('ShelfCard item count updates live when document is added to ShelfBloc', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pumpAndSettle();

    final BuildContext homeContext = tester.element(find.byType(HomeScreen));
    final shelfBloc = BlocProvider.of<ShelfBloc>(homeContext);

    // Verify Fantasy card exists initially
    final fantasyCard = find.widgetWithText(ShelfCard, 'Fantasy');
    expect(fantasyCard, findsOneWidget);

    // Dispatch a new document import event live while sitting on the home screen
    shelfBloc.add(
      const AddDocumentToShelfEvent(
        title: 'New Magical Chronicle',
        shelf: 'Fantasy',
        filePath: '/docs/fantasy.pdf',
      ),
    );

    // Pump frame to process BLoC emit and trigger reactive UI rebuild
    await tester.pumpAndSettle();

    // Verify Fantasy shelf card still exists and updated reactively
    expect(find.widgetWithText(ShelfCard, 'Fantasy'), findsOneWidget);
  });
}
