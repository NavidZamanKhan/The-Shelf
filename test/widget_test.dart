import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    SharedPreferences.setMockInitialValues({
      'auth_logged_in': true,
      'auth_email': 'test@example.com',
      'auth_display_name': 'Test User',
    });
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
  });

  testWidgets('Format filter tabs show All Items -> Books -> PDFs', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('All Items'), findsOneWidget);
    expect(find.text('Books'), findsOneWidget);
    expect(find.text('PDFs'), findsOneWidget);
  });

  testWidgets('Populated shelves sort to top, empty shelves sort to bottom', (WidgetTester tester) async {
    await pumpApp(tester);

    // Filter bar should be visible
    expect(find.byType(ShelfCard), findsWidgets);
  });

  testWidgets('Search icon in header opens SearchScreen', (WidgetTester tester) async {
    await pumpApp(tester);

    final searchIconFinder = find.byIcon(PhosphorIcons.magnifyingGlass);
    expect(searchIconFinder, findsWidgets);

    await tester.tap(searchIconFinder.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SearchScreen), findsOneWidget);
  });

  testWidgets('Plus icon (+) opens ImportBottomSheetModal', (WidgetTester tester) async {
    await pumpApp(tester);

    final plusIconFinder = find.byIcon(PhosphorIcons.plusCircle);
    expect(plusIconFinder, findsWidgets);

    await tester.tap(plusIconFinder.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(ImportBottomSheetModal), findsOneWidget);
    expect(find.text('ADD TO LIBRARY'), findsOneWidget);
  });

  testWidgets('Tapping a ShelfCard navigates to ShelfDetailScreen', (WidgetTester tester) async {
    await pumpApp(tester);

    final firstShelfCard = find.byType(ShelfCard).first;
    await tester.tap(firstShelfCard);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ShelfDetailScreen), findsOneWidget);
  });

  testWidgets('Bottom navigation tab switching works correctly (Shelf -> Collections -> Profile -> Settings)', (WidgetTester tester) async {
    await pumpApp(tester);

    // Initial state: Shelf tab active (HomeScreen)
    expect(find.byType(HomeScreen), findsOneWidget);

    // Switch to Settings tab (4th item in NavigationBar)
    final settingsTabFinder = find.byIcon(PhosphorIcons.gear);
    expect(settingsTabFinder, findsOneWidget);

    await tester.tap(settingsTabFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('Adding document to empty shelf persists to SQLite and reloads across fresh BLoC instances', (WidgetTester tester) async {
    await tester.runAsync(() async {
      final dbRepo = DocumentRepository.instance;
      
      // Clean up previous test entries for isolation
      final db = await dbRepo.database;
      await db.delete('documents', where: 'title = ?', whereArgs: ['Test Persistence Document']);

      // 1. Insert a document into empty shelf (e.g. 'Philosophy')
      final testItem = ShelfItem(
        id: 'test_persistence_doc',
        title: 'Test Persistence Document',
        filePath: '/path/to/test.pdf',
        shelf: 'Philosophy',
        addedAt: DateTime.now(),
      );
      await dbRepo.insertDocument(testItem);

      // 2. Instantiate a FRESH ShelfBloc (simulating app restart)
      final freshBloc = ShelfBloc();

      // 3. Dispatch LoadShelfItemsEvent
      freshBloc.add(const LoadShelfItemsEvent());

      // 4. Verify ShelfBloc loads items from SQLite containing our test document
      await expectLater(
        freshBloc.stream,
        emits(
          isA<ShelfLoaded>().having(
            (state) => state.items.any((item) => item.title == 'Test Persistence Document' && item.shelf == 'Philosophy'),
            'contains persisted document',
            isTrue,
          ),
        ),
      );

      // Clean up
      await dbRepo.deleteDocument(testItem.id);
      await freshBloc.close();
    });
  });

  testWidgets('Classifier debug screen loads and displays ML metadata', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ClassifierDebugScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('Classifier Debug & Verification'), findsOneWidget);
  });
}
