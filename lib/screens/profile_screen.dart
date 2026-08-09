import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/collection/collection_bloc.dart';
import 'package:the_shelf/blocs/collection/collection_state.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/services/document_repository.dart';
import 'package:the_shelf/theme/app_color_palette.dart';
import 'package:the_shelf/theme/app_theme.dart';

/// Profile screen showing user identity, genre distribution donut chart,
/// account stats, and sign-out action.
///
/// Auth-dependent fields use mock placeholders until Firebase Auth is wired
/// in Stages 2-3. The donut chart uses REAL SQLite genre data.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, int> _genreDistribution = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGenreData();
  }

  Future<void> _loadGenreData() async {
    final distribution = await DocumentRepository.instance.getGenreDistribution();
    if (mounted) {
      setState(() {
        _genreDistribution = distribution;
        _isLoading = false;
      });
    }
  }

  // --- Genre color mapping for donut chart segments ---
  static const List<Color> _genreColors = [
    Color(0xFF4A9088), // Teal primary
    Color(0xFFC85A30), // Terracotta
    Color(0xFF7FB8AF), // Teal light
    Color(0xFFF0997B), // Terracotta light
    Color(0xFF6B8E85), // Muted teal
    Color(0xFFD4956B), // Warm amber
    Color(0xFF8AAEA8), // Desaturated teal
    Color(0xFFB59A8B), // Warm taupe
  ];

  Color _colorForIndex(int index) {
    return _genreColors[index % _genreColors.length];
  }

  /// Build top-4 genre entries + "Other" bucket from real distribution data.
  List<_ChartEntry> _buildChartEntries() {
    if (_genreDistribution.isEmpty) return [];

    final entries = _genreDistribution.entries.toList();
    final List<_ChartEntry> chartEntries = [];

    // Top 4 genres shown individually
    final topCount = entries.length > 4 ? 4 : entries.length;
    for (int i = 0; i < topCount; i++) {
      chartEntries.add(_ChartEntry(
        label: entries[i].key,
        count: entries[i].value,
        color: _colorForIndex(i),
      ));
    }

    // Remaining genres grouped as "Other"
    if (entries.length > 4) {
      int otherCount = 0;
      for (int i = 4; i < entries.length; i++) {
        otherCount += entries[i].value;
      }
      if (otherCount > 0) {
        chartEntries.add(_ChartEntry(
          label: 'Other',
          count: otherCount,
          color: _colorForIndex(4),
        ));
      }
    }

    return chartEntries;
  }

  void _showAuthRequiredToast(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Sign in to $action',
          style: const TextStyle(
            fontFamily: AppTheme.serifFontFamily,
            fontSize: 14,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Banner Header with Avatar ---
          _buildBannerHeader(activePalette),

          // --- Identity Section ---
          _buildIdentitySection(activePalette),

          const SizedBox(height: 20),

          // --- Donut Chart Card ---
          _buildDonutChartCard(activePalette),

          const SizedBox(height: 16),

          // --- Stat Strip ---
          _buildStatStrip(activePalette),

          const SizedBox(height: 24),

          // --- Log Out Button ---
          _buildLogOutButton(activePalette),
        ],
      ),
    );
  }

  // ================================================================
  // BANNER HEADER
  // ================================================================

  Widget _buildBannerHeader(AppColorPalette activePalette) {
    return Container(
      height: 130,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            activePalette.gradientStart,
            activePalette.primaryAccent.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Avatar badge — positioned to overlap bottom of banner
          Positioned(
            left: 20,
            bottom: -30,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: activePalette.primaryAccent,
                borderRadius: AppTheme.asymmetricBadgeRadius,
                border: Border.all(
                  color: activePalette.cardBackground,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: activePalette.primaryAccent.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                // TODO(auth): Replace with user initials from FirebaseAuth.instance.currentUser.displayName
                child: Text(
                  'G',
                  style: TextStyle(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),

          // Edit photo button — top right of banner
          Positioned(
            right: 16,
            top: 16,
            child: GestureDetector(
              onTap: () => _showAuthRequiredToast('edit your photo'),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: activePalette.cardBackground.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  PhosphorIcons.camera,
                  size: 18,
                  color: activePalette.primaryText.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // IDENTITY SECTION (name, email, edit profile button)
  // ================================================================

  Widget _buildIdentitySection(AppColorPalette activePalette) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + email
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TODO(auth): Replace with FirebaseAuth.instance.currentUser?.displayName
                Text(
                  'Guest User',
                  style: TextStyle(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: activePalette.primaryText,
                  ),
                ),
                const SizedBox(height: 3),
                // TODO(auth): Replace with FirebaseAuth.instance.currentUser?.email
                Text(
                  'Sign in to see your profile',
                  style: TextStyle(
                    fontSize: 13,
                    color: activePalette.secondaryText,
                  ),
                ),
              ],
            ),
          ),

          // Edit profile button
          GestureDetector(
            onTap: () => _showAuthRequiredToast('edit your profile'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: AppTheme.asymmetricBadgeRadius,
                border: Border.all(
                  color: activePalette.cardBorder,
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    PhosphorIcons.pencilSimple,
                    size: 15,
                    color: activePalette.primaryText,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Edit profile',
                    style: TextStyle(
                      fontFamily: AppTheme.serifFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: activePalette.primaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DONUT CHART CARD
  // ================================================================

  Widget _buildDonutChartCard(AppColorPalette activePalette) {
    final chartEntries = _buildChartEntries();
    final totalBooks = _genreDistribution.values.fold(0, (a, b) => a + b);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: activePalette.cardBackground,
          borderRadius: AppTheme.asymmetricCardRadius,
          border: Border.all(color: activePalette.cardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your library by genre',
              style: TextStyle(
                fontFamily: AppTheme.serifFontFamily,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: activePalette.primaryText,
              ),
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              SizedBox(
                height: 140,
                child: Center(
                  child: CircularProgressIndicator(
                    color: activePalette.primaryAccent,
                    strokeWidth: 2,
                  ),
                ),
              )
            else if (chartEntries.isEmpty)
              SizedBox(
                height: 140,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        PhosphorIcons.chartDonut,
                        size: 36,
                        color: activePalette.desaturatedEmptyText,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Import books to see\nyour genre breakdown',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: AppTheme.serifFontFamily,
                          fontSize: 14,
                          color: activePalette.desaturatedEmptyText,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Row(
                children: [
                  // Donut chart with center overlay
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 42,
                            startDegreeOffset: -90,
                            sections: chartEntries.map((entry) {
                              return PieChartSectionData(
                                value: entry.count.toDouble(),
                                color: entry.color,
                                radius: 22,
                                showTitle: false,
                                borderSide: BorderSide.none,
                              );
                            }).toList(),
                          ),
                        ),
                        // Center total count overlay
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$totalBooks',
                              style: TextStyle(
                                fontFamily: AppTheme.serifFontFamily,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: activePalette.primaryText,
                              ),
                            ),
                            Text(
                              totalBooks == 1 ? 'book' : 'books',
                              style: TextStyle(
                                fontSize: 12,
                                color: activePalette.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 24),

                  // Legend
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: chartEntries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: entry.color,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _shortenGenreName(entry.label),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: activePalette.primaryText,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '· ${entry.count}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: activePalette.secondaryText,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Shorten long genre names for legend readability.
  String _shortenGenreName(String name) {
    const abbreviations = {
      'Self-Help & Personal Development': 'Self-Help',
      'Biography & Memoir': 'Bio/Memoir',
      'Graphic Novels & Comics': 'Comics',
      'Anime & Manga': 'Manga',
      'Historical Fiction': 'Hist. Fiction',
      'Science Fiction': 'Sci-Fi',
    };
    return abbreviations[name] ?? name;
  }

  // ================================================================
  // STAT STRIP (3-column: Collections | Member since | Signed in via)
  // ================================================================

  Widget _buildStatStrip(AppColorPalette activePalette) {
    final collectionCount = context.watch<CollectionBloc>().state;
    final count = collectionCount is CollectionLoaded
        ? collectionCount.collections.length
        : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: activePalette.cardBackground,
          borderRadius: AppTheme.asymmetricCardRadius,
          border: Border.all(color: activePalette.cardBorder, width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              _buildStatCell(
                '$count',
                'Collections',
                activePalette,
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: activePalette.cardBorder,
              ),
              // TODO(auth): Replace with FirebaseAuth.instance.currentUser?.metadata.creationTime
              _buildStatCell(
                '—',
                'Member since',
                activePalette,
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: activePalette.cardBorder,
              ),
              // TODO(auth): Replace with user.providerData[0].providerId
              _buildStatCell(
                'Not signed in',
                'Signed in via',
                activePalette,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCell(
    String value,
    String label,
    AppColorPalette activePalette,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: AppTheme.serifFontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: activePalette.primaryText,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: activePalette.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // LOG OUT BUTTON
  // ================================================================

  Widget _buildLogOutButton(AppColorPalette activePalette) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        // TODO(auth): Wire real FirebaseAuth.instance.signOut() + GoogleSignIn().signOut()
        onTap: () => _showAuthRequiredToast('log out'),
        child: AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 120),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: AppTheme.asymmetricCardRadius,
              border: Border.all(
                color: Colors.redAccent.withValues(alpha: 0.6),
                width: 1.2,
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  PhosphorIcons.signOut,
                  size: 18,
                  color: Colors.redAccent,
                ),
                SizedBox(width: 8),
                Text(
                  'Log out',
                  style: TextStyle(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Internal data model for a single chart legend entry.
class _ChartEntry {
  final String label;
  final int count;
  final Color color;

  const _ChartEntry({
    required this.label,
    required this.count,
    required this.color,
  });
}
