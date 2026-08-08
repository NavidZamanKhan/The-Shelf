import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/models/mock_shelf_items.dart';
import 'package:the_shelf/screens/shelf_detail_screen.dart';
import 'package:the_shelf/theme/app_theme.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _query = '';
  String _selectedShelfFilter = 'All Shelves';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 68.0,
        backgroundColor: AppTheme.softParchmentBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            PhosphorIcons.arrowLeft,
            color: AppTheme.deepEspressoPrimaryText,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            height: 44.0,
            decoration: BoxDecoration(
              color: AppTheme.pureWhiteCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.softWarmBorder, width: 1.0),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              autofocus: true,
              style: const TextStyle(
                fontSize: 15,
                color: AppTheme.deepEspressoPrimaryText,
              ),
              decoration: InputDecoration(
                hintText: 'Search documents or shelves...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.warmRustSecondaryText,
                ),
                prefixIcon: const Icon(
                  PhosphorIcons.magnifyingGlass,
                  size: 20,
                  color: AppTheme.terracottaPrimary,
                ),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          PhosphorIcons.x,
                          size: 18,
                          color: AppTheme.warmRustSecondaryText,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ),
      ),
      body: BlocBuilder<ShelfBloc, ShelfState>(
        builder: (context, state) {
          if (state is ShelfLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.terracottaPrimary),
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

            // Available shelf filter options
            final Set<String> shelfNames = effectiveItems.map((e) => e.shelf).toSet();
            final List<String> availableShelves = ['All Shelves', ...shelfNames.toList()..sort()];

            // Filter items by search query and selected shelf filter chip
            final normalizedQuery = _query.trim().toLowerCase();
            final List<ShelfItem> matchedItems = effectiveItems.where((item) {
              // 1. Shelf filter constraint
              if (_selectedShelfFilter != 'All Shelves' &&
                  item.shelf.toLowerCase() != _selectedShelfFilter.toLowerCase()) {
                return false;
              }

              // 2. Query text constraint (matches title or shelf name)
              if (normalizedQuery.isEmpty) return true;

              final titleMatch = item.title.toLowerCase().contains(normalizedQuery);
              final shelfMatch = item.shelf.toLowerCase().contains(normalizedQuery);
              return titleMatch || shelfMatch;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Horizontal In-Search Shelf Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: availableShelves.map((shelf) {
                      final bool isSelected = _selectedShelfFilter == shelf;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedShelfFilter = shelf;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.terracottaPrimary
                                : AppTheme.pureWhiteCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.terracottaPrimary
                                  : AppTheme.softWarmBorder,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            shelf,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : AppTheme.deepEspressoPrimaryText,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const Divider(height: 1, color: AppTheme.softWarmBorder),

                // Results Content Area
                Expanded(
                  child: _buildResultsContent(context, normalizedQuery, matchedItems),
                ),
              ],
            );
          }

          return const Center(child: Text('Initialize Shelf'));
        },
      ),
    );
  }

  Widget _buildResultsContent(
    BuildContext context,
    String query,
    List<ShelfItem> items,
  ) {
    // Initial Empty State (Query is empty)
    if (query.isEmpty && _selectedShelfFilter == 'All Shelves') {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.subtleBadgeBackground,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    PhosphorIcons.magnifyingGlass,
                    size: 32,
                    color: AppTheme.terracottaPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Search Your Library',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: AppTheme.serifFontFamily,
                      color: AppTheme.deepEspressoPrimaryText,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Type a book title or shelf category name to instantly search across all 17 shelves.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.warmRustSecondaryText,
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  'Fantasy',
                  'Science Fiction',
                  'History',
                  'Mystery',
                ].map((suggestion) {
                  return ActionChip(
                    label: Text(suggestion),
                    backgroundColor: AppTheme.pureWhiteCard,
                    side: const BorderSide(color: AppTheme.softWarmBorder),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.deepEspressoPrimaryText,
                    ),
                    onPressed: () {
                      _searchController.text = suggestion;
                      _searchController.selection = TextSelection.fromPosition(
                        TextPosition(offset: suggestion.length),
                      );
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    }

    // No Results Matching Query
    if (items.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.desaturatedEmptyBadge,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    PhosphorIcons.magnifyingGlass,
                    size: 32,
                    color: AppTheme.desaturatedEmptyText,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                query.isNotEmpty ? 'No Documents Found' : 'No Items in Shelf',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: AppTheme.serifFontFamily,
                      color: AppTheme.deepEspressoPrimaryText,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                query.isNotEmpty
                    ? 'No documents matched "$query". Try checking for typos or searching with a different keyword.'
                    : 'No documents found matching the selected shelf filter.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.warmRustSecondaryText,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Matched Results List View
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return _SearchResultTile(
          item: item,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ShelfDetailScreen(category: item.shelf),
              ),
            );
          },
        );
      },
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final ShelfItem item;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.item,
    required this.onTap,
  });

  String _getFileExtension(String path) {
    final ext = path.split('.').last.toUpperCase();
    if (ext.length <= 4) return ext;
    return 'DOC';
  }

  @override
  Widget build(BuildContext context) {
    final ext = _getFileExtension(item.filePath);
    final iconData = AppTheme.getCategoryIcon(item.shelf);

    return InkWell(
      onTap: onTap,
      borderRadius: AppTheme.asymmetricCardRadius,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.pureWhiteCard,
          borderRadius: AppTheme.asymmetricCardRadius,
          border: Border.all(color: AppTheme.softWarmBorder, width: 1.0),
        ),
        child: Row(
          children: [
            // Icon Badge
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                gradient: AppTheme.badgeGradient,
                borderRadius: AppTheme.asymmetricBadgeRadius,
              ),
              child: Center(
                child: Icon(
                  iconData,
                  color: AppTheme.deepEspressoPrimaryText,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Title & Location Context Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontFamily: AppTheme.serifFontFamily,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.deepEspressoPrimaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.shelf} • $ext',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.warmRustSecondaryText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Format Tag Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.subtleBadgeBackground,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppTheme.softWarmBorder, width: 1),
              ),
              child: Text(
                ext,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.deepEspressoPrimaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
