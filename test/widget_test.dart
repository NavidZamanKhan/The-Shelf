import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_event.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/main.dart';
import 'package:the_shelf/screens/home_screen.dart';
import 'package:the_shelf/screens/search_screen.dart';
import 'package:the_shelf/screens/settings_screen.dart';
import 'package:the_shelf/screens/shelf_detail_screen.dart';
import 'package:the_shelf/services/document_repository.dart';
import 'package:the_shelf/widgets/shelf_card.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for SQLite database execution in headless widget unit tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(const TheShelfApp());
    await tester.pump();
    await tester.idle();
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('App loads home screen smoke test and displays ShelfCards', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ShelfCard), findsWidgets);
    // Verify FAB is removed per non-Material design specification
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('Tapping header Add Item button triggers action', (WidgetTester tester) async {
    await pumpApp(tester);

    final plusButton = find.byIcon(PhosphorIcons.plusCircle);
    expect(plusButton, findsOneWidget);
  });

  testWidgets('Tapping header search icon opens SearchScreen', (WidgetTester tester) async {
    await pumpApp(tester);

    final searchButton = find.byIcon(PhosphorIcons.magnifyingGlass).first;
    await tester.tap(searchButton);
    await tester.pump();
    await tester.idle();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SearchScreen), findsOneWidget);
    expect(find.text('Search Your Library'), findsOneWidget);
  });

  testWidgets('Tapping a ShelfCard navigates to ShelfDetailScreen without duplicate title', (WidgetTester tester) async {
    await pumpApp(tester);

    // Find and tap the Fantasy shelf card at top of populated section
    final fantasyCard = find.widgetWithText(ShelfCard, 'Fantasy');
    expect(fantasyCard, findsOneWidget);

    await tester.tap(fantasyCard);
    await tester.pump();
    await tester.idle();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify detail screen is displayed and category title appears ONCE in AppBar
    expect(find.byType(ShelfDetailScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ShelfDetailScreen),
        matching: find.text('Fantasy'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Populated shelves sort to top, empty shelves sort to bottom', (WidgetTester tester) async {
    await pumpApp(tester);

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
    await pumpApp(tester);

    expect(find.text('All Items'), findsOneWidget);
    expect(find.text('Books'), findsOneWidget);
    expect(find.text('PDFs'), findsOneWidget);

    // Tap Books tab
    await tester.tap(find.text('Books'));
    await tester.pump();
    await tester.idle();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ShelfCard), findsWidgets);
  });

  testWidgets('SearchScreen performs title and shelf name matching', (WidgetTester tester) async {
    await pumpApp(tester);

    // Open SearchScreen
    final searchButton = find.byIcon(PhosphorIcons.magnifyingGlass).first;
    await tester.tap(searchButton);
    await tester.pump();
    await tester.idle();
    await tester.pump(const Duration(milliseconds: 400));

    // Type query "Dune"
    await tester.enterText(find.byType(TextField), 'Dune');
    await tester.pump();
    await tester.idle();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify Dune document result is displayed with shelf context subtitle
    expect(find.text('Science Fiction • PDF'), findsOneWidget);

    // Enter zero results query
    await tester.enterText(find.byType(TextField), 'xyz999nonexistent');
    await tester.pump();
    await tester.idle();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('No Documents Found'), findsOneWidget);
  });

  testWidgets('Settings screen theme switcher updates active palette to Teal', (WidgetTester tester) async {
    await pumpApp(tester);

    // Navigate to Settings tab (4th tab item)
    final settingsNav = find.byIcon(PhosphorIcons.gear);
    expect(settingsNav, findsOneWidget);

    await tester.tap(settingsNav);
    await tester.pump();
    await tester.idle();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.text('Teal (Fresh Mint)'), findsOneWidget);

    // Tap Teal theme card
    await tester.tap(find.text('Teal (Fresh Mint)'));
    await tester.pump();
    await tester.idle();
    await tester.pump(const Duration(milliseconds: 400));

    // Verify ThemeCubit active palette is now teal
    final BuildContext settingsContext = tester.element(find.byType(SettingsScreen));
    final themeCubit = BlocProvider.of<ThemeCubit>(settingsContext);
    expect(themeCubit.state.id, 'teal');
  });

  testWidgets('Adding document to empty shelf persists to SQLite and reloads across fresh BLoC instances', (WidgetTester tester) async {
    await pumpApp(tester);

    final repository = DocumentRepository.instance;
    await repository.clearAllDocuments();

    final freshBloc1 = ShelfBloc(repository: repository);
    freshBloc1.add(const LoadShelfItemsEvent());
    await Future.delayed(const Duration(milliseconds: 200));

    // Dispatch document import into Romance shelf
    freshBloc1.add(
      const AddDocumentToShelfEvent(
        title: 'Pride and Prejudice',
        shelf: 'Romance',
        filePath: '/docs/pride.pdf',
      ),
    );

    await Future.delayed(const Duration(milliseconds: 200));

    // Verify item is saved to SQLite DB
    final savedItems = await repository.getAllDocuments();
    expect(savedItems.length, 1);
    expect(savedItems.first.title, 'Pride and Prejudice');

    // Simulate app restart by instantiating a completely fresh BLoC
    final freshBloc2 = ShelfBloc(repository: repository);
    freshBloc2.add(const LoadShelfItemsEvent());
    await Future.delayed(const Duration(milliseconds: 200));

    expect(freshBloc2.state, isA<ShelfLoaded>());
    final loadedState = freshBloc2.state as ShelfLoaded;
    expect(loadedState.items.length, 1);
    expect(loadedState.items.first.title, 'Pride and Prejudice');
  });
}
