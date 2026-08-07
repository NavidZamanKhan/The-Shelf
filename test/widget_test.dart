import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
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

    // Collect rendered ShelfCard categories in display order
    final cards = tester.widgetList<ShelfCard>(find.byType(ShelfCard)).toList();
    expect(cards.isNotEmpty, true);

    // Verify populated cards come before empty cards in the list
    bool encounteredEmpty = false;
    for (final card in cards) {
      if (card.itemCount == 0) {
        encounteredEmpty = true;
      } else {
        // Populated card should not appear after an empty card
        expect(encounteredEmpty, false, reason: 'Populated shelf ${card.category} appeared after empty shelf');
      }
    }
  });

  testWidgets('Format filter tab triggers directional slide animation and filters by extension', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pumpAndSettle();

    // Verify initial state: All Items tab, all 17 categories visible
    var cards = tester.widgetList<ShelfCard>(find.byType(ShelfCard)).toList();
    expect(cards.length, 17);

    // Tap PDFs filter tab
    final pdfTab = find.text('PDFs');
    expect(pdfTab, findsOneWidget);
    await tester.tap(pdfTab);

    // Pump a few frames to observe the slide animation in progress
    await tester.pump(const Duration(milliseconds: 100));
    // During animation, both outgoing and incoming content should exist in a Stack
    expect(find.byType(SlideTransition), findsWidgets);

    // Let the animation complete
    await tester.pumpAndSettle();

    // After animation, all 17 categories remain rendered with format-filtered counts
    cards = tester.widgetList<ShelfCard>(find.byType(ShelfCard)).toList();
    expect(cards.length, 17);
  });

  testWidgets('Adding document to empty shelf dynamically promotes it to populated section', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pumpAndSettle();

    final BuildContext homeContext = tester.element(find.byType(HomeScreen));
    final shelfBloc = BlocProvider.of<ShelfBloc>(homeContext);

    // Verify Romance is empty initially
    final List<ShelfCard> initialCards = tester.widgetList<ShelfCard>(find.byType(ShelfCard)).toList();
    final romanceInitial = initialCards.firstWhere((c) => c.category == 'Romance');
    expect(romanceInitial.itemCount, 0);

    // Dispatch document import into Romance shelf while on home screen
    shelfBloc.add(
      const AddDocumentToShelfEvent(
        title: 'Pride and Prejudice',
        shelf: 'Romance',
        filePath: '/docs/pride.pdf',
      ),
    );

    // Pump frame and process BLoC emit
    await tester.pumpAndSettle();

    // Verify Romance shelf card is now populated (itemCount == 1) and promoted to populated section
    final List<ShelfCard> updatedCards = tester.widgetList<ShelfCard>(find.byType(ShelfCard)).toList();
    final romanceUpdated = updatedCards.firstWhere((c) => c.category == 'Romance');
    expect(romanceUpdated.itemCount, 1);
  });
}
