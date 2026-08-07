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
import 'package:the_shelf/theme/app_theme.dart';
import 'package:the_shelf/widgets/app_bottom_navigation_bar.dart';
import 'package:the_shelf/widgets/app_header.dart';
import 'package:the_shelf/widgets/category_filter_chips.dart';
import 'package:the_shelf/widgets/import_bottom_sheet_modal.dart';
import 'package:the_shelf/widgets/import_confirmation_sheet.dart';
import 'package:the_shelf/widgets/shelf_section.dart';

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
            const _PlaceholderView(title: 'Collections', iconData: PhosphorIcons.books),
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
        floatingActionButton: _currentNavIndex == 0
            ? FloatingActionButton.extended(
                onPressed: () => ImportBottomSheetModal.show(context),
                icon: const Icon(PhosphorIcons.plus, size: 20),
                label: const Text(
                  'Add Item',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              )
            : null,
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

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Reusable compact header
        const AppHeader(title: 'The Shelf'),

        // Reusable category filter chips row
        SliverToBoxAdapter(
          child: CategoryFilterChips(
            selectedCategory: selectedCategory,
            onCategorySelected: onCategorySelected,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 12)),

        // Shelf Items Content grouped by Category
        BlocBuilder<ShelfBloc, ShelfState>(
          builder: (context, state) {
            if (state is ShelfLoading) {
              return const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppTheme.terracottaPrimary),
                ),
              );
            } else if (state is ShelfLoaded) {
              // Combine user imported items with gated dev mock items for visual verification
              List<ShelfItem> effectiveItems = List.from(state.items);
              if (showMockDataInDev) {
                // Prepend user-imported items, append mock items if not already present
                final existingIds = effectiveItems.map((e) => e.id).toSet();
                for (final mock in devMockShelfItems) {
                  if (!existingIds.contains(mock.id)) {
                    effectiveItems.add(mock);
                  }
                }
              }

              // Filter by selected category chip
              if (selectedCategory != 'All Items') {
                effectiveItems = effectiveItems
                    .where((item) => item.shelf.trim().toLowerCase() == selectedCategory.trim().toLowerCase())
                    .toList();
              }

              if (effectiveItems.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.books,
                          size: 64,
                          color: AppTheme.terracottaLightAccent,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Your Shelf is Empty',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            selectedCategory == 'All Items'
                                ? 'Tap "+ Add Item" below to import documents or scan books.'
                                : 'No books found in the "$selectedCategory" category.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Group items by category (shelf)
              final Map<String, List<ShelfItem>> groupedItems = {};
              for (final item in effectiveItems) {
                groupedItems.putIfAbsent(item.shelf, () => []).add(item);
              }

              final categories = groupedItems.keys.toList();

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final category = categories[index];
                      final categoryItems = groupedItems[category]!;
                      return ShelfSection(
                        category: category,
                        items: categoryItems,
                        sectionIndex: index,
                        onItemTap: (item) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Opening "${item.title}"...'),
                              duration: const Duration(seconds: 1),
                              backgroundColor: AppTheme.terracottaPrimary,
                            ),
                          );
                        },
                      );
                    },
                    childCount: categories.length,
                  ),
                ),
              );
            }

            return const SliverFillRemaining(
              child: Center(child: Text('Initialize Shelf')),
            );
          },
        ),
      ],
    );
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
