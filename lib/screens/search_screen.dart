import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/shelf/shelf_bloc.dart';
import 'package:the_shelf/blocs/shelf/shelf_state.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/models/mock_shelf_items.dart';
import 'package:the_shelf/screens/shelf_detail_screen.dart';
import 'package:the_shelf/theme/app_color_palette.dart';
import 'package:the_shelf/theme/app_theme.dart';

/// Fullscreen search interface with title and shelf category matching
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
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
    // Request focus on open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return Scaffold(
      backgroundColor: activePalette.background,
      appBar: AppBar(
        backgroundColor: activePalette.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIcons.arrowLeft, color: activePalette.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          style: TextStyle(
            fontFamily: AppTheme.serifFontFamily,
            fontSize: 18,
            color: activePalette.primaryText,
          ),
          decoration: InputDecoration(
            hintText: 'Search documents or shelves...',
            hintStyle: TextStyle(
              fontFamily: AppTheme.serifFontFamily,
              fontSize: 18,
              color: activePalette.secondaryText.withValues(alpha: 0.6),
            ),
            border: InputBorder.none,
          ),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: Icon(PhosphorIcons.x, color: activePalette.secondaryText),
              onPressed: () {
                _searchController.clear();
              },
            ),
        ],
      ),
      body: BlocBuilder<ShelfBloc, ShelfState>(
        builder: (context, state) {
          if (state is ShelfLoading) {
            return Center(
              child: CircularProgressIndicator(color: activePalette.primaryAccent),
            );
          }

          // Extract items safely from loaded state or default to empty
          final List<ShelfItem> rawItems = (state is ShelfLoaded) ? state.items : [];

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
                              ? activePalette.primaryAccent
                              : activePalette.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? activePalette.primaryAccent
                                : activePalette.cardBorder,
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
                                : activePalette.primaryText,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Divider(height: 1, color: activePalette.cardBorder),

              // Results Content Area
              Expanded(
                child: _buildResultsContent(context, normalizedQuery, matchedItems, activePalette),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResultsContent(
    BuildContext context,
    String query,
    List<ShelfItem> items,
    AppColorPalette activePalette,
  ) {
    if (query.isEmpty && items.isEmpty) {
      return _buildEmptyState(
        context,
        icon: PhosphorIcons.magnifyingGlass,
        title: 'Search Your Library',
        subtitle: 'Type a document title or shelf category above',
        activePalette: activePalette,
      );
    }

    if (items.isEmpty) {
      return _buildEmptyState(
        context,
        icon: PhosphorIcons.fileSearch,
        title: 'No Documents Found',
        subtitle: 'No items match "$query" in ${_selectedShelfFilter.toLowerCase()}',
        activePalette: activePalette,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: activePalette.cardBorder.withValues(alpha: 0.5),
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _SearchResultTile(
          item: item,
          query: query,
          activePalette: activePalette,
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

  Widget _buildEmptyState(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required AppColorPalette activePalette,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: activePalette.desaturatedEmptyBadge,
                borderRadius: AppTheme.asymmetricBadgeRadius,
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 32,
                  color: activePalette.desaturatedEmptyText,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.serifFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: activePalette.primaryText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: activePalette.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final ShelfItem item;
  final String query;
  final AppColorPalette activePalette;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.item,
    required this.query,
    required this.activePalette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ext = _getFileExtension(item.filePath);
    final iconData = _getFormatIcon(ext);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: activePalette.cardBackground,
          borderRadius: AppTheme.asymmetricBadgeRadius,
          border: Border.all(color: activePalette.cardBorder, width: 1),
        ),
        child: Center(
          child: Icon(
            iconData,
            size: 20,
            color: activePalette.primaryAccent,
          ),
        ),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          fontFamily: AppTheme.serifFontFamily,
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: activePalette.primaryText,
        ),
      ),
      subtitle: Text(
        '${item.shelf} • $ext',
        style: TextStyle(
          fontSize: 12,
          color: activePalette.secondaryText,
        ),
      ),
      trailing: Icon(
        PhosphorIcons.caretRight,
        size: 16,
        color: activePalette.secondaryText,
      ),
    );
  }

  String _getFileExtension(String path) {
    final ext = path.split('.').last.toUpperCase();
    return ext.length > 5 ? 'DOC' : ext;
  }

  IconData _getFormatIcon(String ext) {
    switch (ext) {
      case 'PDF':
        return PhosphorIcons.filePdf;
      case 'EPUB':
        return PhosphorIcons.bookOpen;
      default:
        return PhosphorIcons.fileText;
    }
  }
}
