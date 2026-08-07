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

/// Directional slide transition widget for tab-driven content switching.
///
/// Tracks the previous tab index to determine slide direction:
/// - Moving to a higher tab index → old content slides out LEFT, new slides in from RIGHT
/// - Moving to a lower tab index → old content slides out RIGHT, new slides in from LEFT
///
/// Uses 350ms duration with Curves.easeOutCubic — longer than the old 280ms because
/// a full-width slide needs more time to read clearly. easeOutCubic gives a natural
/// deceleration (fast start, gentle landing) that feels like physical page momentum.
class _ShelfView extends StatefulWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const _ShelfView({
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  State<_ShelfView> createState() => _ShelfViewState();
}

class _ShelfViewState extends State<_ShelfView> with SingleTickerProviderStateMixin {
  static const List<String> _filterTabs = ['All Items', 'PDFs', 'EPUBs'];

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

  late AnimationController _slideController;
  late Animation<Offset> _outgoingSlide;
  late Animation<Offset> _incomingSlide;
  late Animation<double> _outgoingFade;
  late Animation<double> _incomingFade;

  String _displayedCategory = 'All Items';
  String? _previousCategory;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _displayedCategory = widget.selectedCategory;
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _setupAnimations(slideForward: true);
  }

  void _setupAnimations({required bool slideForward}) {
    // slideForward = true means moving to a higher tab index:
    //   outgoing slides from center → left (Offset(0,0) → Offset(-1,0))
    //   incoming slides from right → center (Offset(1,0) → Offset(0,0))
    // slideForward = false means moving to a lower tab index:
    //   outgoing slides from center → right (Offset(0,0) → Offset(1,0))
    //   incoming slides from left → center (Offset(-1,0) → Offset(0,0))
    final double outEnd = slideForward ? -1.0 : 1.0;
    final double inStart = slideForward ? 1.0 : -1.0;

    final curved = CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    );

    _outgoingSlide = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(outEnd, 0),
    ).animate(curved);

    _incomingSlide = Tween<Offset>(
      begin: Offset(inStart, 0),
      end: Offset.zero,
    ).animate(curved);

    _outgoingFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _incomingFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _ShelfView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _animateToNewTab(oldWidget.selectedCategory, widget.selectedCategory);
    }
  }

  void _animateToNewTab(String fromCategory, String toCategory) {
    if (_isAnimating) {
      // If mid-animation, snap to the end and start a new transition
      _slideController.value = 1.0;
    }

    final fromIndex = _filterTabs.indexOf(fromCategory);
    final toIndex = _filterTabs.indexOf(toCategory);
    final slideForward = toIndex > fromIndex;

    setState(() {
      _previousCategory = fromCategory;
      _isAnimating = true;
    });

    _slideController.reset();
    _setupAnimations(slideForward: slideForward);

    _slideController.forward().then((_) {
      if (mounted) {
        setState(() {
          _displayedCategory = toCategory;
          _previousCategory = null;
          _isAnimating = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

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
            selectedCategory: widget.selectedCategory,
            onCategorySelected: widget.onCategorySelected,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Reactive Shelf Cards Content with directional slide transition
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

              if (_isAnimating && _previousCategory != null) {
                // During animation: render both outgoing and incoming content in a Stack
                return SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _slideController,
                    builder: (context, _) {
                      return ClipRect(
                        child: Stack(
                          children: [
                            // Outgoing content (old tab) sliding away
                            SlideTransition(
                              position: _outgoingSlide,
                              child: FadeTransition(
                                opacity: _outgoingFade,
                                child: _buildShelfList(
                                  effectiveItems,
                                  _previousCategory!,
                                ),
                              ),
                            ),
                            // Incoming content (new tab) sliding in
                            SlideTransition(
                              position: _incomingSlide,
                              child: FadeTransition(
                                opacity: _incomingFade,
                                child: _buildShelfList(
                                  effectiveItems,
                                  widget.selectedCategory,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }

              // Static state (no animation in progress)
              return SliverToBoxAdapter(
                child: _buildShelfList(
                  effectiveItems,
                  _displayedCategory,
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

  /// Builds the shelf card list for a given format filter, with populated-first sorting.
  Widget _buildShelfList(List<ShelfItem> effectiveItems, String filterCategory) {
    // Compute category item counts filtered by selected format extension
    final Map<String, int> countsMap = {};
    for (final item in effectiveItems) {
      if (_matchesFormatFilter(item, filterCategory)) {
        final normalizedKey = _findMatchingCategoryKey(item.shelf);
        countsMap[normalizedKey] = (countsMap[normalizedKey] ?? 0) + 1;
      }
    }

    // Sort all 17 categories populated-first based on matching format counts
    final List<String> sortedCategories = _sortCategories(
      List.from(all17Categories),
      countsMap,
    );

    return Padding(
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
