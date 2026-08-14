import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/document_import/document_import_bloc.dart';
import 'package:the_shelf/blocs/document_import/document_import_event.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/theme/app_theme.dart';

/// Bespoke compact single-option bottom sheet modal for document import.
class ImportBottomSheetModal extends StatelessWidget {
  const ImportBottomSheetModal({super.key});

  static Future<void> show(BuildContext context) {
    final activePalette = context.read<ThemeCubit>().state;

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: activePalette.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (modalContext) {
        return BlocProvider.value(
          value: context.read<DocumentImportBloc>(),
          child: const ImportBottomSheetModal(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Drag Handle Indicator
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: activePalette.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Section Label
            Text(
              'ADD TO LIBRARY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: activePalette.secondaryText,
              ),
            ),
            const SizedBox(height: 12),

            // Tailored Single-Option Card
            InkWell(
              onTap: () {
                Navigator.pop(context);
                context.read<DocumentImportBloc>().add(const PickAndExtractPdfEvent());
              },
              borderRadius: AppTheme.asymmetricCardRadius,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: activePalette.background,
                  borderRadius: AppTheme.asymmetricCardRadius,
                  border: Border.all(
                    color: activePalette.cardBorder,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Icon Badge
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: activePalette.subtleBadgeBackground,
                        borderRadius: AppTheme.asymmetricBadgeRadius,
                        border: Border.all(
                          color: activePalette.cardBorder,
                          width: 1.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          PhosphorIcons.filePlus,
                          color: activePalette.primaryAccent,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Option Titles
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import PDF / Document',
                            style: TextStyle(
                              fontFamily: AppTheme.serifFontFamily,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: activePalette.primaryText,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Add PDF or digital files from device storage',
                            style: TextStyle(
                              fontSize: 12,
                              color: activePalette.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Icon(
                      PhosphorIcons.caretRightBold,
                      size: 16,
                      color: activePalette.secondaryText,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
