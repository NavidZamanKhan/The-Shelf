import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/document_import/document_import_bloc.dart';
import 'package:the_shelf/blocs/document_import/document_import_event.dart';
import 'package:the_shelf/blocs/document_import/document_import_state.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_event.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/models/mock_shelf_items.dart';
import 'package:the_shelf/screens/shelf_detail_screen.dart';
import 'package:the_shelf/theme/app_theme.dart';
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

  @override
  Widget build(BuildContext context) {
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
                backgroundColor: AppTheme.terracottaPrimary,
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
        body: IndexedStack(
          index: _currentNavIndex,
          children: [
            _ShelfView(
              selectedCategory: _selectedCategory,
              onCategorySelected: (category) {
                setState(() {
                  _selectedCategory = category;
                });
              },
            ),
            const _PlaceholderView(title: 'Collections', iconData: PhosphorIcons.bookmarkSimple),
            const _PlaceholderView(title: 'Insights', iconData: PhosphorIcons.sparkle),
            const _PlaceholderView(title: 'Settings', iconData: PhosphorIcons.gear),
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

  const _ShelfView({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

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
    return CustomScrollView(
      slivers: [
        // Reusable compact app header with integrated Add Item action button
        AppHeader(
          title: 'The Shelf',
          onAddItemPressed: () => ImportBottomSheetModal.show(context),
        ),

        // Category filter underline tabs row
        SliverToBoxAdapter(
          child: CategoryFilterChips(
            selectedCategory: selectedCategory,
            onCategorySelected: onCategorySelected,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Reactive Animated Shelf Cards Content
        BlocBuilder<ShelfBloc, ShelfState>(
          builder: (context, state) {
            if (state is ShelfLoading) {
              return const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.terracottaPrimary),
                ),
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

              // Compute category item counts filtered by selected format extension
              final Map<String, int> countsMap = {};
              for (final item in effectiveItems) {
                if (_matchesFormatFilter(item, selectedCategory)) {
                  final normalizedKey = _findMatchingCategoryKey(item.shelf);
                  countsMap[normalizedKey] = (countsMap[normalizedKey] ?? 0) + 1;
                }
              }

              // Sort all 17 categories populated-first based on matching format counts
              final List<String> sortedCategories = _sortCategories(
                List.from(all17Categories),
                countsMap,
              );

              // AnimatedSwitcher guarantees fluid slide+fade transition on every tab switch
              return SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeInOutCubic,
                  switchOutCurve: Curves.easeInOutCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.03, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    key: ValueKey<String>(selectedCategory),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: List.generate(sortedCategories.length, (index) {
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
                      }),
                    ),
                  ),
                ),
              );
            }

            return const SliverFillRemaining(
              child: Center(child: Text('Initialize Shelf')),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
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
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              size: 64,
              color: AppTheme.terracottaLightAccent,
            ),
            const SizedBox(height: 16),
            Text(
              '$title Feature Coming Soon',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
