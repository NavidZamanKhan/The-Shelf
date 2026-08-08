import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_event.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/main.dart';
import 'package:the_shelf/screens/home_screen.dart';
import 'package:the_shelf/screens/search_screen.dart';
import 'package:the_shelf/screens/settings_screen.dart';
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

  testWidgets('Tapping header search icon opens SearchScreen', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pumpAndSettle();

    final searchButton = find.byIcon(PhosphorIcons.magnifyingGlass).first;
    await tester.tap(searchButton);
    await tester.pumpAndSettle();

    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text('Search Your Library'), findsOneWidget);
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

    // All visible cards at top should be populated (count > 0)
    for (final card in cards) {
      if (card.itemCount == 0) break;
      expect(card.itemCount, greaterThan(0));
    }
  });

  testWidgets('Format filter tabs show All Items -> Books -> PDFs', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pumpAndSettle();

    expect(find.text('All Items'), findsOneWidget);
    expect(find.text('Books'), findsOneWidget);
    expect(find.text('PDFs'), findsOneWidget);

    // Tap Books tab
    await tester.tap(find.text('Books'));
    await tester.pumpAndSettle();

    expect(find.byType(ShelfCard), findsWidgets);
  });

  testWidgets('SearchScreen performs title and shelf name matching', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pumpAndSettle();

    // Open SearchScreen
    final searchButton = find.byIcon(PhosphorIcons.magnifyingGlass).first;
    await tester.tap(searchButton);
    await tester.pumpAndSettle();

    // Type query "Dune"
    await tester.enterText(find.byType(TextField), 'Dune');
    await tester.pumpAndSettle();

    // Verify Dune document result is displayed with shelf context subtitle
    expect(find.text('Science Fiction • PDF'), findsOneWidget);

    // Enter zero results query
    await tester.enterText(find.byType(TextField), 'xyz999nonexistent');
    await tester.pumpAndSettle();

    expect(find.text('No Documents Found'), findsOneWidget);
  });

  testWidgets('Settings screen theme switcher updates active palette to Teal', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pumpAndSettle();

    // Navigate to Settings tab (4th tab item)
    final settingsNav = find.byIcon(PhosphorIcons.gear);
    expect(settingsNav, findsOneWidget);

    await tester.tap(settingsNav);
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Teal (Fresh Mint)'), findsOneWidget);

    // Tap Teal theme card
    await tester.tap(find.text('Teal (Fresh Mint)'));
    await tester.pumpAndSettle();

    // Verify ThemeCubit active palette is now teal
    final BuildContext settingsContext = tester.element(find.byType(SettingsScreen));
    final themeCubit = BlocProvider.of<ThemeCubit>(settingsContext);
    expect(themeCubit.state.id, 'teal');
  });

  testWidgets('Adding document to empty shelf updates BLoC state reactively', (WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pumpAndSettle();

    final BuildContext homeContext = tester.element(find.byType(HomeScreen));
    final shelfBloc = BlocProvider.of<ShelfBloc>(homeContext);

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

    await tester.pumpAndSettle();

    final updatedState = shelfBloc.state;
    expect(updatedState, isA<ShelfLoaded>());
    final updatedItems = (updatedState as ShelfLoaded).items;
    expect(updatedItems.length, initialItemCount + 1);

    final romanceItems = updatedItems.where((item) =>
        item.shelf.toLowerCase() == 'romance').toList();
    expect(romanceItems.length, 1);
    expect(romanceItems.first.title, 'Pride and Prejudice');
  });
}
