import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:the_shelf/blocs/collection/collection_bloc.dart';
import 'package:the_shelf/blocs/collection/collection_state.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/models/mock_shelf_items.dart';
import 'package:the_shelf/models/sort_option.dart';
import 'package:the_shelf/screens/collection_detail_screen.dart';
import 'package:the_shelf/screens/profile_screen.dart';
import 'package:the_shelf/screens/search_screen.dart';
import 'package:the_shelf/screens/settings_screen.dart';
import 'package:the_shelf/screens/shelf_detail_screen.dart';
import 'package:the_shelf/theme/app_color_palette.dart';
import 'package:the_shelf/theme/app_theme.dart';
import 'package:the_shelf/widgets/app_bottom_navigation_bar.dart';
import 'package:the_shelf/widgets/app_header.dart';
import 'package:the_shelf/widgets/category_filter_chips.dart';
import 'package:the_shelf/widgets/collection_card.dart';
import 'package:the_shelf/widgets/create_collection_modal.dart';
import 'package:the_shelf/blocs/document_import/document_import_bloc.dart';
import 'package:the_shelf/blocs/document_import/document_import_event.dart';
import 'package:the_shelf/blocs/document_import/document_import_state.dart';
import 'package:the_shelf/blocs/shelf/shelf_event.dart';
import 'package:the_shelf/widgets/import_bottom_sheet_modal.dart';
import 'package:the_shelf/widgets/import_confirmation_sheet.dart';
import 'package:the_shelf/widgets/shelf_card.dart';
import 'package:the_shelf/widgets/sort_options_modal.dart';

/// All 17 target shelf categories specified in design requirements
const List<String> all17Categories = [
  'Fantasy',
  'Historical Fiction',
  'Mystery',
  'Romance',
  'Science Fiction',
  'Horror',
  'Thriller',
  'Young Adult',
  'Graphic Novels & Comics',
  'Anime & Manga',
  'Children\'s',
  'Poetry',
  'History',
  'Biography & Memoir',
  'Philosophy',
  'Self-Help & Personal Development',
  'Miscellaneous',
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;
  int _selectedFilterIndex = 0;
  SortOption _currentSortOption = SortOption.populatedFirst;
  late final PageController _pageController;

  static const List<String> _formatTabs = ['All Items', 'Books', 'PDFs'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedFilterIndex);
    _loadSavedSortOption();
  }

  Future<void> _loadSavedSortOption() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('shelf_sort_option');
      if (savedName != null && mounted) {
        setState(() {
          _currentSortOption = SortOption.fromName(savedName);
        });
      }
    } catch (e) {
      debugPrint('Error loading saved sort option: $e');
    }
  }

  Future<void> _updateSortOption(SortOption option) async {
    setState(() {
      _currentSortOption = option;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('shelf_sort_option', option.name);
    } catch (e) {
      debugPrint('Error saving sort option: $e');
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onFilterTabSelected(int index) {
    setState(() {
      _selectedFilterIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _selectedFilterIndex = index;
    });
  }

  void _onBottomNavSelected(int index) {
    setState(() {
      _selectedNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return Scaffold(
      backgroundColor: activePalette.background,
      body: SafeArea(
        bottom: false,
        child: BlocListener<DocumentImportBloc, DocumentImportState>(
          listener: (context, importState) async {
            if (importState is DocumentImportSuccess) {
              final summary = importState.summary;
              final result = await showModalBottomSheet<Map<String, dynamic>>(
                context: context,
                isScrollControlled: true,
                backgroundColor: activePalette.cardBackground,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                builder: (modalContext) => ImportConfirmationSheet(summary: summary),
              );

              if (result != null && result['confirmed'] == true && context.mounted) {
                final String title = result['title'] as String;
                final String shelf = result['shelf'] as String;

                context.read<ShelfBloc>().add(
                      AddDocumentToShelfEvent(
                        title: title,
                        shelf: shelf,
                        filePath: summary.filePath,
                      ),
                    );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added "$title" to $shelf!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }

              if (context.mounted) {
                context.read<DocumentImportBloc>().add(const ResetImportEvent());
              }
            } else if (importState is DocumentImportFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Import failed: ${importState.errorMessage}'),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<DocumentImportBloc>().add(const ResetImportEvent());
            }
          },
          child: Column(
            children: [
              // Static App Header (magGlass triggers SearchScreen, funnel triggers SortOptionsModal)
              AppHeader(
                isSliver: false,
                onAddItemPressed: _selectedNavIndex == 1
                    ? null
                    : () {
                        ImportBottomSheetModal.show(context);
                      },
                onSearchPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const SearchScreen()),
                  );
                },
                onFilterPressed: () {
                  SortOptionsModal.show(
                    context: context,
                    currentOption: _currentSortOption,
                    onOptionSelected: (newOption) {
                      _updateSortOption(newOption);
                    },
                  );
                },
              ),

            // Tab navigation body or Settings tab
            Expanded(
              child: IndexedStack(
                index: _selectedNavIndex,
                children: [
                  // Tab 0: Main Shelf PageView navigation
                  _ShelfView(
                    selectedFilterIndex: _selectedFilterIndex,
                    formatTabs: _formatTabs,
                    pageController: _pageController,
                    sortOption: _currentSortOption,
                    onFilterTabSelected: _onFilterTabSelected,
                    onPageChanged: _onPageChanged,
                    activePalette: activePalette,
                  ),

                  // Tab 1: Collections screen
                  const _CollectionsView(),

                  // Tab 2: Profile screen
                  const ProfileScreen(),

                  // Tab 3: Settings screen with theme switcher
                  const SettingsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
      bottomNavigationBar: AppBottomNavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: _onBottomNavSelected,
      ),
    );
  }
}

class _ShelfView extends StatelessWidget {
  final int selectedFilterIndex;
  final List<String> formatTabs;
  final PageController pageController;
  final SortOption sortOption;
  final ValueChanged<int> onFilterTabSelected;
  final ValueChanged<int> onPageChanged;
  final AppColorPalette activePalette;

  const _ShelfView({
    required this.selectedFilterIndex,
    required this.formatTabs,
    required this.pageController,
    required this.sortOption,
    required this.onFilterTabSelected,
    required this.onPageChanged,
    required this.activePalette,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Underline Category Filter Tabs
        CategoryFilterChips(
          categories: formatTabs,
          selectedCategory: formatTabs[selectedFilterIndex],
          onCategorySelected: (category) {
            final idx = formatTabs.indexOf(category);
            if (idx != -1) {
              onFilterTabSelected(idx);
            }
          },
        ),

        // PageView: each page is an independently scrollable shelf list
        Expanded(
          child: PageView.builder(
            controller: pageController,
            onPageChanged: onPageChanged,
            itemCount: formatTabs.length,
            itemBuilder: (context, pageIndex) {
              final filterName = formatTabs[pageIndex];
              return _buildShelfList(context, activePalette, filterName);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildShelfList(
    BuildContext context,
    AppColorPalette activePalette,
    String filterName,
  ) {
    return BlocBuilder<ShelfBloc, ShelfState>(
      builder: (context, state) {
        if (state is ShelfLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: activePalette.primaryAccent,
            ),
          );
        }

        // Extract items safely from loaded state or default to empty
        final List<ShelfItem> rawItems = (state is ShelfLoaded)
            ? state.items
            : [];

        // Combine real state items with gated dev mock items for visual verification
        List<ShelfItem> effectiveItems = List.from(rawItems);
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

        // Sort categories according to active sort option
        final List<String> sortedCategories = _sortCategories(
          List.from(all17Categories),
          countsMap,
          sortOption,
        );

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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

  /// Normalizes incoming shelf category strings
  String _findMatchingCategoryKey(String shelfName) {
    final trimmed = shelfName.trim();
    for (final cat in all17Categories) {
      if (cat.toLowerCase() == trimmed.toLowerCase()) {
        return cat;
      }
    }
    return 'Miscellaneous';
  }

  /// Multi-criteria sorting algorithm supporting Alphabetical (A-Z / Z-A), Count, & Populated-First
  List<String> _sortCategories(
    List<String> categories,
    Map<String, int> countsMap,
    SortOption option,
  ) {
    final result = List<String>.from(categories);

    switch (option) {
      case SortOption.alphabeticalAsc:
        result.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        break;

      case SortOption.alphabeticalDesc:
        result.sort((a, b) => b.toLowerCase().compareTo(a.toLowerCase()));
        break;

      case SortOption.mostItems:
        result.sort((a, b) {
          final cA = countsMap[a] ?? 0;
          final cB = countsMap[b] ?? 0;
          final cmp = cB.compareTo(cA);
          if (cmp != 0) return cmp;
          return a.compareTo(b);
        });
        break;

      case SortOption.leastItems:
        result.sort((a, b) {
          final cA = countsMap[a] ?? 0;
          final cB = countsMap[b] ?? 0;
          final cmp = cA.compareTo(cB);
          if (cmp != 0) return cmp;
          return a.compareTo(b);
        });
        break;

      case SortOption.populatedFirst:
        final List<String> populated = [];
        final List<String> empty = [];

        for (final cat in result) {
          final count = countsMap[cat] ?? 0;
          if (count > 0) {
            populated.add(cat);
          } else {
            empty.add(cat);
          }
        }

        populated.sort((a, b) {
          final countA = countsMap[a] ?? 0;
          final countB = countsMap[b] ?? 0;
          final countCompare = countB.compareTo(countA);
          if (countCompare != 0) return countCompare;
          return a.compareTo(b);
        });

        empty.sort((a, b) => a.compareTo(b));
        return [...populated, ...empty];
    }

    return result;
  }
}

class _CollectionsView extends StatelessWidget {
  const _CollectionsView();

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return BlocBuilder<CollectionBloc, CollectionState>(
      builder: (context, state) {
        if (state is CollectionLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: activePalette.primaryAccent,
            ),
          );
        }

        final collections = (state is CollectionLoaded)
            ? state.collections
            : [];

        return Column(
          children: [
            // Collections Header Action Strip
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR COLLECTIONS',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color: activePalette.secondaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${collections.length} of 20 collections created',
                        style: TextStyle(
                          fontSize: 12,
                          color: activePalette.secondaryText.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: collections.length >= 20
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Maximum limit of 20 collections reached.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        : () => CreateCollectionModal.show(context),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: collections.length >= 20
                            ? activePalette.subtleBadgeBackground
                            : activePalette.primaryAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: collections.length >= 20
                              ? activePalette.cardBorder
                              : activePalette.primaryAccent.withValues(alpha: 0.5),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          PhosphorIcons.plus,
                          size: 20,
                          color: collections.length >= 20
                              ? activePalette.secondaryText
                              : activePalette.primaryAccent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Collections Grid/List
            Expanded(
              child: collections.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              PhosphorIcons.folderPlus,
                              size: 48,
                              color: activePalette.secondaryText.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No Collections Yet',
                              style: TextStyle(
                                fontFamily: AppTheme.serifFontFamily,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: activePalette.primaryText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Create custom collections like "Favorites" or "Summer Reading" to organize your books.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: activePalette.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: collections.length,
                      itemBuilder: (context, index) {
                        final collection = collections[index];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: CollectionCard(
                            collection: collection,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => CollectionDetailScreen(collection: collection),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
