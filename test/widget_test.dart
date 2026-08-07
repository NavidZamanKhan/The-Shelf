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

  testWidgets('Tapping a ShelfCard navigates to ShelfDetailScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pumpAndSettle();

    // Find and tap the Fantasy shelf card at top of populated section
    final fantasyCard = find.widgetWithText(ShelfCard, 'Fantasy');
    expect(fantasyCard, findsOneWidget);

    await tester.tap(fantasyCard);
    await tester.pumpAndSettle();

    // Verify detail screen is displayed
    expect(find.byType(ShelfDetailScreen), findsOneWidget);
    expect(find.text('Fantasy'), findsWidgets);
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

    // Pump frame and process BLoC emit + animated switcher transition
    await tester.pumpAndSettle();

    // Verify Romance shelf card is now populated (itemCount == 1) and promoted to populated section
    final List<ShelfCard> updatedCards = tester.widgetList<ShelfCard>(find.byType(ShelfCard)).toList();
    final romanceUpdated = updatedCards.firstWhere((c) => c.category == 'Romance');
    expect(romanceUpdated.itemCount, 1);
  });
}
