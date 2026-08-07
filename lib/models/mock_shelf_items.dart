import 'package:flutter/foundation.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';

/// DEVELOPMENT-ONLY MOCK DATA CONVENIENCE
///
/// CAUTION: This mock dataset is strictly intended for dev/testing visual verification
/// of the warm terracotta design system on the home screen.
///
/// Toggle [showMockDataInDev] or set to `false` to disable mock fallback in production.
const bool showMockDataInDev = kDebugMode;

/// Sample realistic shelf items across various categories
final List<ShelfItem> devMockShelfItems = [
  ShelfItem(
    id: 'mock_1',
    title: 'The Name of the Wind',
    shelf: 'Fantasy',
    filePath: '/books/fantasy/name_of_the_wind.epub',
    addedAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
  ShelfItem(
    id: 'mock_2',
    title: 'The Name of the Rose',
    shelf: 'Historical Fiction',
    filePath: '/documents/history/name_of_the_rose.pdf',
    addedAt: DateTime.now().subtract(const Duration(days: 4)),
  ),
  ShelfItem(
    id: 'mock_3',
    title: 'Dune',
    shelf: 'Science Fiction',
    filePath: '/books/scifi/dune.pdf',
    addedAt: DateTime.now().subtract(const Duration(days: 1)),
  ),
  ShelfItem(
    id: 'mock_4',
    title: 'Meditations',
    shelf: 'Philosophy',
    filePath: '/documents/philosophy/meditations.epub',
    addedAt: DateTime.now().subtract(const Duration(days: 7)),
  ),
  ShelfItem(
    id: 'mock_5',
    title: 'Atomic Habits',
    shelf: 'Self-Help & Personal Development',
    filePath: '/documents/selfhelp/atomic_habits.pdf',
    addedAt: DateTime.now().subtract(const Duration(days: 3)),
  ),
  ShelfItem(
    id: 'mock_6',
    title: 'Watchmen',
    shelf: 'Graphic Novels & Comics',
    filePath: '/comics/watchmen.pdf',
    addedAt: DateTime.now().subtract(const Duration(days: 5)),
  ),
  ShelfItem(
    id: 'mock_7',
    title: 'The Hound of the Baskervilles',
    shelf: 'Mystery',
    filePath: '/classics/hound_baskervilles.txt',
    addedAt: DateTime.now().subtract(const Duration(days: 6)),
  ),
  ShelfItem(
    id: 'mock_8',
    title: 'Sapiens: A Brief History of Humankind',
    shelf: 'History',
    filePath: '/books/history/sapiens.pdf',
    addedAt: DateTime.now().subtract(const Duration(days: 8)),
  ),
];
