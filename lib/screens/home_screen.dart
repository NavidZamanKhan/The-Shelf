import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/collection/collection_bloc.dart';
import 'package:the_shelf/blocs/collection/collection_state.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/models/collection_model.dart';
import 'package:the_shelf/models/mock_shelf_items.dart';
import 'package:the_shelf/screens/collection_detail_screen.dart';
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
import 'package:the_shelf/widgets/import_bottom_sheet_modal.dart';
import 'package:the_shelf/widgets/shelf_card.dart';

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
  late final PageController _pageController;

  static const List<String> _formatTabs = ['All Items', 'Books', 'PDFs'];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedFilterIndex);
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
        child: Column(
          children: [
            // Static App Header (contextual plus trigger, magGlass triggers SearchScreen)
            AppHeader(
              isSliver: false,
              onAddItemPressed: () {
                if (_selectedNavIndex == 1) {
                  CreateCollectionModal.show(context);
                } else {
                  ImportBottomSheetModal.show(context);
                }
              },
              onSearchPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const SearchScreen()),
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
                    onFilterTabSelected: _onFilterTabSelected,
                    onPageChanged: _onPageChanged,
                    activePalette: activePalette,
                  ),

                  // Tab 1: Collections screen
                  const _CollectionsView(),

                  // Tab 2: Insights placeholder screen
                  _buildPlaceholderScreen(
                    'Insights',
                    PhosphorIcons.sparkle,
                    activePalette,
                  ),

                  // Tab 3: Settings screen with theme switcher
                  const SettingsScreen(),
                ],
              ),
            ),
          ],
        ),
      ),

      // Custom non-Material bottom navigation footer bar
      bottomNavigationBar: AppBottomNavigationBar(
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: _onBottomNavSelected,
      ),
    );
  }

  Widget _buildPlaceholderScreen(
    String title,
    IconData icon,
    AppColorPalette activePalette,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: activePalette.primaryAccent.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontFamily: AppTheme.serifFontFamily,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: activePalette.primaryText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: TextStyle(fontSize: 14, color: activePalette.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _ShelfView extends StatelessWidget {
  final int selectedFilterIndex;
  final List<String> formatTabs;
  final PageController pageController;
  final ValueChanged<int> onFilterTabSelected;
  final ValueChanged<int> onPageChanged;
  final AppColorPalette activePalette;

  const _ShelfView({
    required this.selectedFilterIndex,
    required this.formatTabs,
    required this.pageController,
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

        // Sort all 17 categories populated-first based on matching format counts
        final List<String> sortedCategories = _sortCategories(
          List.from(all17Categories),
          countsMap,
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

  /// Populated-first stable sort algorithm
  List<String> _sortCategories(
    List<String> categories,
    Map<String, int> countsMap,
  ) {
    final List<String> populated = [];
    final List<String> empty = [];

    for (final cat in categories) {
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
}

class _CollectionsView extends StatelessWidget {
  const _CollectionsView();

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return BlocConsumer<CollectionBloc, CollectionState>(
      listener: (context, state) {
        if (state is CollectionLoaded && state.notificationMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.notificationMessage!),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is CollectionLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: activePalette.primaryAccent,
            ),
          );
        }

        final collections = (state is CollectionLoaded) ? state.collections : <CollectionModel>[];
        final isAtCap = collections.length >= 20;

        return Column(
          children: [
            // Top Section Bar: Counter & Create Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Custom Collections',
                        style: TextStyle(
                          fontFamily: AppTheme.serifFontFamily,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: activePalette.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${collections.length} / 20 created',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isAtCap ? Colors.redAccent : activePalette.secondaryText,
                        ),
                      ),
                    ],
                  ),
                  OutlinedButton.icon(
                    onPressed: isAtCap
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Maximum limit of 20 collections reached.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        : () => CreateCollectionModal.show(context),
                    icon: Icon(
                      PhosphorIcons.plus,
                      size: 15,
                      color: isAtCap ? activePalette.secondaryText : activePalette.primaryAccent,
                    ),
                    label: Text(
                      'New Collection',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isAtCap ? activePalette.secondaryText : activePalette.primaryAccent,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isAtCap
                          ? activePalette.subtleBadgeBackground
                          : activePalette.primaryAccent.withOpacity(0.04),
                      side: BorderSide(
                        color: isAtCap ? activePalette.cardBorder : activePalette.primaryAccent,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),

            // Main Body: Empty State vs Collection Cards
            Expanded(
              child: collections.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: activePalette.primaryAccent.withOpacity(0.12),
                                borderRadius: AppTheme.asymmetricBadgeRadius,
                              ),
                              child: Center(
                                child: Icon(
                                  PhosphorIcons.bookmarkSimple,
                                  size: 40,
                                  color: activePalette.primaryAccent,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No Collections Yet',
                              style: TextStyle(
                                fontFamily: AppTheme.serifFontFamily,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: activePalette.primaryText,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap "+ New Collection" above to create custom groupings of your documents across genre shelves.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.4,
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
                        return CollectionCard(
                          collection: collection,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => CollectionDetailScreen(
                                  collection: collection,
                                ),
                              ),
                            );
                          },
                          onMoreTap: () {
                            CreateCollectionModal.show(
                              context,
                              initialCollection: collection,
                            );
                          },
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

