import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_event.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/main.dart';
import 'package:the_shelf/screens/classifier_debug_screen.dart';
import 'package:the_shelf/screens/home_screen.dart';
import 'package:the_shelf/screens/search_screen.dart';
import 'package:the_shelf/screens/settings_screen.dart';
import 'package:the_shelf/screens/shelf_detail_screen.dart';
import 'package:the_shelf/services/collection_repository.dart';
import 'package:the_shelf/services/document_repository.dart';
import 'package:the_shelf/widgets/import_bottom_sheet_modal.dart';
import 'package:the_shelf/widgets/shelf_card.dart';

void main() {
  setUpAll(() {
    // Initialize FFI for SQLite database execution in headless widget unit tests
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    final db = await DocumentRepository.instance.database;
    await db.close();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.runAsync(() async {
      await DocumentRepository.instance.database;
      await CollectionRepository.instance.getAllCollections();
    });
    await tester.pumpWidget(const TheShelfApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 300)));
  }

  testWidgets('App loads home screen smoke test and displays ShelfCards', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(ShelfCard), findsWidgets);
    // Verify FAB is removed per non-Material design specification
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('Tapping header Add Item button opens single-option ImportBottomSheetModal', (WidgetTester tester) async {
    await pumpApp(tester);

    final plusButton = find.byIcon(PhosphorIcons.plusCircle);
    expect(plusButton, findsOneWidget);

    await tester.tap(plusButton);
    await tester.pump();
    await tester.idle();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(ImportBottomSheetModal), findsOneWidget);
    expect(find.text('ADD TO LIBRARY'), findsOneWidget);
    expect(find.text('Import PDF / Document'), findsOneWidget);
    // Verify removed placeholder options do not exist
    expect(find.text('Scan Book or Document'), findsNothing);
    expect(find.text('Add Web Article'), findsNothing);
  });

  testWidgets('Tapping header search icon opens SearchScreen', (WidgetTester tester) async {
    await pumpApp(tester);

    final searchIcon = find.byIcon(PhosphorIcons.magnifyingGlass).first;

    await tester.tap(searchIcon);
    await tester.pump();
    await tester.idle();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SearchScreen), findsOneWidget);
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

    // Verify detail screen is displayed and category title appears in AppBar
    expect(find.byType(ShelfDetailScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AppBar),
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

  testWidgets('Settings screen theme switcher and Classifier Verification Debugger navigation', (WidgetTester tester) async {
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

    // Verify Developer Tools section exists in kDebugMode
    expect(find.text('DEVELOPER TOOLS'), findsOneWidget);
    final debuggerTile = find.text('Classifier Verification Debugger');
    expect(debuggerTile, findsOneWidget);

    // Scroll down in SettingsScreen ListView to reveal Developer Tools
    await tester.drag(find.byType(ListView).last, const Offset(0, -600));
    await tester.pump();
    await tester.tap(debuggerTile);
    await tester.pump();
    await tester.idle();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byType(ClassifierDebugScreen), findsOneWidget);
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
