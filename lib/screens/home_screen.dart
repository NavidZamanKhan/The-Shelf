import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/document_import/document_import_bloc.dart';
import 'package:the_shelf/blocs/document_import/document_import_event.dart';
import 'package:the_shelf/blocs/document_import/document_import_state.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_event.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/models/mock_shelf_items.dart';
import 'package:the_shelf/screens/search_screen.dart';
import 'package:the_shelf/screens/settings_screen.dart';
import 'package:the_shelf/screens/shelf_detail_screen.dart';
import 'package:the_shelf/widgets/app_bottom_navigation_bar.dart';
import 'package:the_shelf/widgets/app_header.dart';
import 'package:the_shelf/widgets/category_filter_chips.dart';
import 'package:the_shelf/widgets/import_bottom_sheet_modal.dart';
import 'package:the_shelf/widgets/import_confirmation_sheet.dart';
import 'package:the_shelf/widgets/shelf_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  String _selectedCategory = 'All Items';
  late PageController _pageController;

  static const List<String> _filterTabs = ['All Items', 'Books', 'PDFs'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(String category) {
    final targetIndex = _filterTabs.indexOf(category);
    if (targetIndex == -1) return;

    setState(() {
      _selectedCategory = category;
    });

    _pageController.animateToPage(
      targetIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageSwiped(int pageIndex) {
    if (pageIndex >= 0 && pageIndex < _filterTabs.length) {
      setState(() {
        _selectedCategory = _filterTabs[pageIndex];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return BlocListener<DocumentImportBloc, DocumentImportState>(
      listener: (context, state) async {
        if (state is DocumentImportSuccess) {
          final summary = state.summary;
          final result = await showModalBottomSheet<Map<String, dynamic>>(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (modalContext) => ImportConfirmationSheet(summary: summary),
          );

          if (!context.mounted) return;

          if (result != null && result['confirmed'] == true) {
            final String title = result['title'];
            final String shelf = result['shelf'];
            context.read<ShelfBloc>().add(
                  AddDocumentToShelfEvent(
                    title: title,
                    shelf: shelf,
                    filePath: summary.filePath,
                  ),
                );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Added "$title" to [$shelf] shelf!'),
                backgroundColor: activePalette.primaryAccent,
              ),
            );
          }
          context.read<DocumentImportBloc>().add(const ResetImportEvent());
        } else if (state is DocumentImportFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error importing document: ${state.errorMessage}'),
              backgroundColor: Colors.redAccent,
            ),
          );
          context.read<DocumentImportBloc>().add(const ResetImportEvent());
        }
      },
      child: Scaffold(
        backgroundColor: activePalette.background,
        body: IndexedStack(
          index: _currentNavIndex,
          children: [
            _ShelfView(
              selectedCategory: _selectedCategory,
              onCategorySelected: _onTabTapped,
              pageController: _pageController,
              onPageSwiped: _onPageSwiped,
            ),
            const _PlaceholderView(title: 'Collections', iconData: PhosphorIcons.bookmarkSimple),
            const _PlaceholderView(title: 'Insights', iconData: PhosphorIcons.sparkle),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: AppBottomNavigationBar(
          selectedIndex: _currentNavIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentNavIndex = index;
            });
          },
        ),
        floatingActionButton: null,
      ),
    );
  }
}

class _ShelfView extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;
  final PageController pageController;
  final ValueChanged<int> onPageSwiped;

  const _ShelfView({
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.pageController,
    required this.onPageSwiped,
  });

  static const List<String> _filterTabs = ['All Items', 'Books', 'PDFs'];

  static const List<String> all17Categories = [
    'Fantasy',
    'Historical Fiction',
    'Mystery',
    'Romance',
    'Science Fiction',
    'Horror',
    'Graphic Novels & Comics',
    'Anime & Manga',
    'Poetry',
    'History',
    'Biography & Memoir',
    'Philosophy',
    'Self-Help & Personal Development',
    'School/Reference',
    'Classics',
    'Religion & Spirituality',
    'Miscellaneous',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App header — fixed at top, outside PageView scroll
        AppHeader(
          title: 'The Shelf',
          onAddItemPressed: () => ImportBottomSheetModal.show(context),
          onSearchPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SearchScreen()),
            );
          },
          isSliver: false,
        ),

        // Category filter underline tabs — fixed, outside PageView scroll
        CategoryFilterChips(
          selectedCategory: selectedCategory,
          onCategorySelected: onCategorySelected,
        ),

        const SizedBox(height: 12),

        // PageView: each page is an independently scrollable shelf list
        Expanded(
          child: PageView.builder(
            controller: pageController,
            onPageChanged: onPageSwiped,
            itemCount: _filterTabs.length,
            itemBuilder: (context, pageIndex) {
              final filterName = _filterTabs[pageIndex];
              return _FormatShelfPage(
                filterName: filterName,
                all17Categories: all17Categories,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FormatShelfPage extends StatelessWidget {
  final String filterName;
  final List<String> all17Categories;

  const _FormatShelfPage({
    required this.filterName,
    required this.all17Categories,
  });

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return BlocBuilder<ShelfBloc, ShelfState>(
      builder: (context, state) {
        if (state is ShelfLoading) {
          return Center(
            child: CircularProgressIndicator(color: activePalette.primaryAccent),
          );
        } else if (state is ShelfLoaded) {
          // Combine real state items with gated dev mock items for visual verification
          List<ShelfItem> effectiveItems = List.from(state.items);
          if (showMockDataInDev) {
            final existingIds = effectiveItems.map((e) => e.id).toSet();
            for (final mock in devMockShelfItems) {
              if (!existingIds.contains(mock.id)) {
                effectiveItems.add(mock);
              }
            }
          }

          // Compute category item counts filtered by this page's format
          final Map<String, int> countsMap = {};
          for (final item in effectiveItems) {
            if (_matchesFormatFilter(item, filterName)) {
              final normalizedKey = _findMatchingCategoryKey(item.shelf);
              countsMap[normalizedKey] = (countsMap[normalizedKey] ?? 0) + 1;
            }
          }

          // Sort all 17 categories populated-first based on matching format counts
          final List<String> sortedCategories = _sortCategories(
            List.from(all17Categories),
            countsMap,
          );

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedCategories.length,
            itemBuilder: (context, index) {
              final catName = sortedCategories[index];
              final itemCount = countsMap[catName] ?? 0;

              return ShelfCard(
                category: catName,
                itemCount: itemCount,
                cardIndex: index,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ShelfDetailScreen(category: catName),
                    ),
                  );
                },
              );
            },
          );
        }

        return const Center(child: Text('Initialize Shelf'));
      },
    );
  }

  /// Extension-based format filtering helper
  bool _matchesFormatFilter(ShelfItem item, String filter) {
    final ext = item.filePath.split('.').last.toLowerCase();
    switch (filter) {
      case 'PDFs':
        return ext == 'pdf';
      case 'EPUBs':
      case 'Books':
        return ext == 'epub';
      case 'All Items':
      default:
        return true;
    }
  }

  /// Populated-First Stable Sorting Algorithm
  List<String> _sortCategories(List<String> categories, Map<String, int> countsMap) {
    final List<String> sorted = List.from(categories);
    sorted.sort((a, b) {
      final countA = countsMap[a] ?? 0;
      final countB = countsMap[b] ?? 0;

      // 1. Primary Sort: Populated (count > 0) vs Empty (count == 0)
      final bool aPopulated = countA > 0;
      final bool bPopulated = countB > 0;
      if (aPopulated && !bPopulated) return -1;
      if (!aPopulated && bPopulated) return 1;

      // 2. Secondary Sort for Populated Shelves: Item count descending
      if (countA != countB) {
        return countB.compareTo(countA);
      }

      // 3. Tertiary Tie-Breaker / Empty Shelves: Alphabetical (A-Z)
      return a.compareTo(b);
    });
    return sorted;
  }

  String _findMatchingCategoryKey(String rawShelf) {
    final lowerRaw = rawShelf.trim().toLowerCase();
    for (final cat in all17Categories) {
      if (cat.trim().toLowerCase() == lowerRaw) return cat;
    }
    return rawShelf;
  }
}

class _PlaceholderView extends StatelessWidget {
  final String title;
  final IconData iconData;

  const _PlaceholderView({
    required this.title,
    required this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return Scaffold(
      backgroundColor: activePalette.background,
      appBar: AppBar(
        backgroundColor: activePalette.background,
        title: Text(
          title,
          style: TextStyle(color: activePalette.primaryText),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 64,
              color: activePalette.lightAccent,
            ),
            const SizedBox(height: 16),
            Text(
              '$title Feature Coming Soon',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: activePalette.primaryText,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
