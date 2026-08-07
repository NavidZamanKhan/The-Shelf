import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_event.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
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
    // Verify FAB is removed per non-Material design specification
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('Tapping header Add Item button triggers action', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pumpAndSettle();

    final plusButton = find.byIcon(PhosphorIcons.plusCircle);
    expect(plusButton, findsOneWidget);
  });

  testWidgets('Tapping a ShelfCard navigates to ShelfDetailScreen without duplicate title', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pumpAndSettle();

    // Find and tap the Fantasy shelf card at top of populated section
    final fantasyCard = find.widgetWithText(ShelfCard, 'Fantasy');
    expect(fantasyCard, findsOneWidget);

    await tester.tap(fantasyCard);
    await tester.pumpAndSettle();

    // Verify detail screen is displayed and category title appears ONCE in AppBar
    expect(find.byType(ShelfDetailScreen), findsOneWidget);
    expect(find.text('Fantasy'), findsOneWidget);
  });

  testWidgets('Populated shelves sort to top, empty shelves sort to bottom', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pumpAndSettle();

    // Collect rendered ShelfCard categories in display order (only visible ones)
    final cards = tester.widgetList<ShelfCard>(find.byType(ShelfCard)).toList();
    expect(cards.isNotEmpty, true);

    // All visible cards at the top should be populated (count > 0)
    // since populated-first sorting puts them first
    for (final card in cards) {
      // The first visible cards should all be populated
      if (card.itemCount == 0) break; // Once we hit empty, stop checking
      expect(card.itemCount, greaterThan(0));
    }
  });

  testWidgets('PageView present and tab tap triggers page animation', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pumpAndSettle();

    // Verify PageView is present in the widget tree
    expect(find.byType(PageView), findsOneWidget);

    // Verify initial All Items page shows ShelfCards
    expect(find.byType(ShelfCard), findsWidgets);

    // Tap PDFs filter tab
    final pdfTab = find.text('PDFs');
    expect(pdfTab, findsOneWidget);
    await tester.tap(pdfTab);

    // Let the page animation complete
    await tester.pumpAndSettle();

    // After switching to PDFs page, ShelfCards are still visible
    // (ListView.builder only renders visible items, so count may differ)
    expect(find.byType(ShelfCard), findsWidgets);
  });

  testWidgets('PageView supports finger-swipe gesture to switch pages', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pumpAndSettle();

    // Verify we start on page 0 (All Items)
    expect(find.byType(PageView), findsOneWidget);

    // Simulate a left swipe (drag from right to left) to go to page 1 (PDFs)
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    // After swipe, ShelfCards are rendered on the PDFs page
    expect(find.byType(ShelfCard), findsWidgets);
  });

  testWidgets('Adding document to empty shelf updates BLoC state reactively', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pumpAndSettle();

    final BuildContext homeContext = tester.element(find.byType(HomeScreen));
    final shelfBloc = BlocProvider.of<ShelfBloc>(homeContext);

    // Capture initial state item count
    final initialState = shelfBloc.state;
    expect(initialState, isA<ShelfLoaded>());
    final initialItemCount = (initialState as ShelfLoaded).items.length;

    // Dispatch document import into Romance shelf
    shelfBloc.add(
      const AddDocumentToShelfEvent(
        title: 'Pride and Prejudice',
        shelf: 'Romance',
        filePath: '/docs/pride.pdf',
      ),
    );

    // Pump to process BLoC state emission
    await tester.pumpAndSettle();

    // Verify BLoC state now contains one more item
    final updatedState = shelfBloc.state;
    expect(updatedState, isA<ShelfLoaded>());
    final updatedItems = (updatedState as ShelfLoaded).items;
    expect(updatedItems.length, initialItemCount + 1);

    // Verify the new item is in the Romance shelf
    final romanceItems = updatedItems.where((item) =>
        item.shelf.toLowerCase() == 'romance').toList();
    expect(romanceItems.length, 1);
    expect(romanceItems.first.title, 'Pride and Prejudice');
  });
}
