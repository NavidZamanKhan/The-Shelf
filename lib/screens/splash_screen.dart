import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/theme/app_theme.dart';

/// Clean minimalist splash screen displayed during initial session checking.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return Scaffold(
      backgroundColor: activePalette.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: activePalette.subtleBadgeBackground,
                borderRadius: AppTheme.asymmetricBadgeRadius,
                border: Border.all(color: activePalette.cardBorder, width: 1.2),
              ),
              child: Icon(
                PhosphorIcons.books,
                size: 38,
                color: activePalette.primaryAccent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The Shelf',
              style: TextStyle(
                fontFamily: AppTheme.serifFontFamily,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: activePalette.primaryText,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: activePalette.primaryAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
