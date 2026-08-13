import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/auth/auth_bloc.dart';
import 'package:the_shelf/blocs/auth/auth_event.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/models/user_profile.dart';
import 'package:the_shelf/theme/app_color_palette.dart';
import 'package:the_shelf/theme/app_theme.dart';

/// Modal bottom sheet allowing users to update display name, reading motto/bio,
/// avatar profile picture, and cover banner photo with Cloud Firestore sync.
class EditProfileModal extends StatefulWidget {
  final UserProfile profile;

  const EditProfileModal({
    super.key,
    required this.profile,
  });

  static Future<void> show(BuildContext context, {required UserProfile profile}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileModal(profile: profile),
    );
  }

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;

  String? _selectedPhotoPath;
  String? _selectedBannerPath;
  bool _isSaving = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.displayName);
    _bioController = TextEditingController(text: widget.profile.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isBanner}) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: isBanner ? 1200 : 600,
        maxHeight: isBanner ? 600 : 600,
        imageQuality: 85,
      );

      if (pickedFile != null && mounted) {
        setState(() {
          if (isBanner) {
            _selectedBannerPath = pickedFile.path;
          } else {
            _selectedPhotoPath = pickedFile.path;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isBanner
                  ? 'Cover photo selected! Tap "Save Changes" to update.'
                  : 'Profile picture selected! Tap "Save Changes" to update.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open photo gallery: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _onSave(BuildContext context) {
    final newName = _nameController.text.trim();
    final newBio = _bioController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your user name'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    context.read<AuthBloc>().add(
          UpdateProfileDetailsRequested(
            displayName: newName,
            bio: newBio.isNotEmpty ? newBio : null,
            photoPath: _selectedPhotoPath,
            bannerPath: _selectedBannerPath,
          ),
        );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 16,
        left: 20,
        right: 20,
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
            const SizedBox(height: 16),

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
            const SizedBox(height: 4),
            Text(
              'Customize your reading persona and profile cover',
              style: TextStyle(
                fontSize: 13,
                color: activePalette.secondaryText,
              ),
            ),
            const SizedBox(height: 20),

            // --- Cover Photo & Avatar Picker Area ---
            _buildMediaPickerHeader(activePalette),
            const SizedBox(height: 24),

            // --- User Name Field ---
            Text(
              'USER NAME',
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
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
                        fontSize: 14,
                        color: activePalette.primaryText,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your user name',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: activePalette.desaturatedEmptyText,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // --- Reading Motto / Bio Field ---
            Text(
              'READING MOTTO / BIO',
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      PhosphorIcons.quotes,
                      size: 18,
                      color: activePalette.secondaryText,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _bioController,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 14,
                        color: activePalette.primaryText,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'Share your reading motto or favorite book quote...',
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: activePalette.desaturatedEmptyText,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Save Button ---
            GestureDetector(
              onTap: _isSaving ? null : () => _onSave(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: activePalette.primaryAccent,
                  borderRadius: AppTheme.asymmetricCardRadius,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : const Text(
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

  Widget _buildMediaPickerHeader(AppColorPalette activePalette) {
    ImageProvider? resolveSafeImageProvider(String? urlStr) {
      if (urlStr == null || urlStr.trim().isEmpty) return null;
      if (urlStr.startsWith('http://') || urlStr.startsWith('https://')) {
        return NetworkImage(urlStr);
      }
      try {
        final file = File(urlStr);
        if (file.existsSync()) {
          return FileImage(file);
        }
      } catch (_) {}
      return null;
    }

    final ImageProvider? bannerImage =
        resolveSafeImageProvider(_selectedBannerPath ?? widget.profile.bannerUrl);
    final ImageProvider? avatarImage =
        resolveSafeImageProvider(_selectedPhotoPath ?? widget.profile.photoUrl);

    return SizedBox(
      height: 145,
      width: double.infinity,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner Container
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: AppTheme.asymmetricCardRadius,
              border: Border.all(color: activePalette.cardBorder, width: 1),
              image: bannerImage != null
                  ? DecorationImage(
                      image: bannerImage,
                      fit: BoxFit.cover,
                    )
                  : null,
              gradient: bannerImage == null
                  ? LinearGradient(
                      colors: [
                        activePalette.gradientStart,
                        activePalette.primaryAccent.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
            ),
          ),

          // Banner edit overlay buttons (top right)
          Positioned(
            right: 10,
            top: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _pickImage(isBanner: false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.userFocus,
                          size: 13,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Profile Photo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _pickImage(isBanner: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          PhosphorIcons.camera,
                          size: 13,
                          color: Colors.white,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Cover Photo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Avatar badge positioned at bottom left (inside parent height bounds)
          Positioned(
            left: 16,
            bottom: 0,
            child: GestureDetector(
              onTap: () => _pickImage(isBanner: false),
              child: Stack(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: activePalette.primaryAccent,
                      borderRadius: AppTheme.asymmetricBadgeRadius,
                      border: Border.all(
                        color: activePalette.cardBackground,
                        width: 3,
                      ),
                      image: avatarImage != null
                          ? DecorationImage(
                              image: avatarImage,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: avatarImage == null
                        ? Center(
                            child: Text(
                              widget.profile.initials,
                              style: const TextStyle(
                                fontFamily: AppTheme.serifFontFamily,
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : null,
                  ),
                  // Camera badge overlay
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: activePalette.primaryAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: activePalette.cardBackground,
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        PhosphorIcons.camera,
                        size: 12,
                        color: Colors.white,
                      ),
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
}
