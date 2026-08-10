import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/auth/auth_bloc.dart';
import 'package:the_shelf/blocs/auth/auth_event.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/theme/app_theme.dart';

/// Modal bottom sheet allowing authenticated users to update their profile display name.
class EditProfileModal extends StatefulWidget {
  final String currentName;

  const EditProfileModal({
    super.key,
    required this.currentName,
  });

  static Future<void> show(BuildContext context, {required String currentName}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileModal(currentName: currentName),
    );
  }

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onSave(BuildContext context) {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty && newName != widget.currentName) {
      context.read<AuthBloc>().add(UpdateDisplayNameRequested(newName));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: activePalette.cardBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border.all(color: activePalette.cardBorder, width: 1),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: activePalette.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header Title
            Row(
              children: [
                Icon(
                  PhosphorIcons.pencilSimple,
                  size: 22,
                  color: activePalette.primaryAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: activePalette.primaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Update your display name across The Shelf',
              style: TextStyle(
                fontSize: 13,
                color: activePalette.secondaryText,
              ),
            ),
            const SizedBox(height: 20),

            // Name Input Field
            Text(
              'DISPLAY NAME',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: activePalette.desaturatedEmptyText,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: activePalette.background,
                borderRadius: AppTheme.asymmetricBadgeRadius,
                border: Border.all(color: activePalette.cardBorder, width: 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.user,
                    size: 18,
                    color: activePalette.secondaryText,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(
                        fontSize: 15,
                        color: activePalette.primaryText,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Enter your name',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save Button
            GestureDetector(
              onTap: () => _onSave(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: activePalette.primaryAccent,
                  borderRadius: AppTheme.asymmetricCardRadius,
                ),
                child: const Text(
                  'Save Changes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
