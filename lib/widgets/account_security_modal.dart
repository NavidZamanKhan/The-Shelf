import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/services/auth_repository.dart';
import 'package:the_shelf/theme/app_color_palette.dart';
import 'package:the_shelf/theme/app_theme.dart';

/// Modal bottom sheet for managing account security, changing passwords,
/// or creating a password for Google-authenticated accounts.
class AccountSecurityModal extends StatefulWidget {
  final String userEmail;
  final bool isGoogleUser;

  const AccountSecurityModal({
    super.key,
    required this.userEmail,
    required this.isGoogleUser,
  });

  static Future<void> show({
    required BuildContext context,
    required String userEmail,
    required bool isGoogleUser,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AccountSecurityModal(
        userEmail: userEmail,
        isGoogleUser: isGoogleUser,
      ),
    );
  }

  @override
  State<AccountSecurityModal> createState() => _AccountSecurityModalState();
}

class _AccountSecurityModalState extends State<AccountSecurityModal> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authRepository = AuthRepository();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit(AppColorPalette palette) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (widget.isGoogleUser) {
        await _authRepository.setPasswordForGoogleUser(
          newPassword: _newPasswordController.text.trim(),
        );
      } else {
        await _authRepository.changePassword(
          currentPassword: _currentPasswordController.text.trim(),
          newPassword: _newPasswordController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isGoogleUser
                ? 'Password created successfully! You can now log in with email or Google.'
                : 'Password updated successfully!',
          ),
          backgroundColor: palette.primaryAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'An unexpected error occurred. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleSendResetEmail(AppColorPalette palette) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authRepository.sendPasswordResetEmail(email: widget.userEmail);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to ${widget.userEmail}'),
          backgroundColor: palette.primaryAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to send reset email.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state.resolvedPalette;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: activePalette.cardBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: activePalette.cardBorder, width: 1.0),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: activePalette.cardBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Modal Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: activePalette.subtleBadgeBackground,
                      borderRadius: AppTheme.asymmetricBadgeRadius,
                    ),
                    child: Center(
                      child: Icon(
                        PhosphorIcons.lockKeyBold,
                        color: activePalette.primaryAccent,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isGoogleUser ? 'Set Account Password' : 'Change Password',
                          style: TextStyle(
                            fontFamily: AppTheme.serifFontFamily,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: activePalette.primaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.isGoogleUser
                              ? 'Create a password to enable email & password sign-in'
                              : 'Update your account security password',
                          style: TextStyle(
                            fontSize: 12,
                            color: activePalette.secondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(PhosphorIcons.warningCircleBold, color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Current Password field (Only if email/password user)
              if (!widget.isGoogleUser) ...[
                Text(
                  'CURRENT PASSWORD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    color: activePalette.secondaryText,
                  ),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrent,
                  style: TextStyle(color: activePalette.primaryText),
                  decoration: _buildInputDecoration(
                    hint: 'Enter your current password',
                    palette: activePalette,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent ? PhosphorIcons.eyeClosed : PhosphorIcons.eye,
                        color: activePalette.secondaryText,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter your current password.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],

              // New Password Field
              Text(
                'NEW PASSWORD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: activePalette.secondaryText,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                style: TextStyle(color: activePalette.primaryText),
                decoration: _buildInputDecoration(
                  hint: 'At least 6 characters',
                  palette: activePalette,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNew ? PhosphorIcons.eyeClosed : PhosphorIcons.eye,
                      color: activePalette.secondaryText,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a new password.';
                  }
                  if (val.trim().length < 6) {
                    return 'Password must be at least 6 characters.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Confirm New Password Field
              Text(
                'CONFIRM NEW PASSWORD',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: activePalette.secondaryText,
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                style: TextStyle(color: activePalette.primaryText),
                decoration: _buildInputDecoration(
                  hint: 'Re-type your new password',
                  palette: activePalette,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? PhosphorIcons.eyeClosed : PhosphorIcons.eye,
                      color: activePalette.secondaryText,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please confirm your new password.';
                  }
                  if (val.trim() != _newPasswordController.text.trim()) {
                    return 'Passwords do not match.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: activePalette.primaryAccent,
                    foregroundColor: activePalette.isDark ? const Color(0xFF141416) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _isLoading ? null : () => _handleSubmit(activePalette),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              activePalette.isDark ? const Color(0xFF141416) : Colors.white,
                            ),
                          ),
                        )
                      : Text(
                          widget.isGoogleUser ? 'Save Password' : 'Update Password',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              // Forgot password / Reset link for password users
              if (!widget.isGoogleUser) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => _handleSendResetEmail(activePalette),
                    child: Text(
                      'Forgot current password? Send reset email',
                      style: TextStyle(
                        fontSize: 13,
                        color: activePalette.primaryAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required AppColorPalette palette,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 14, color: palette.secondaryText.withValues(alpha: 0.6)),
      filled: true,
      fillColor: palette.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: palette.primaryAccent, width: 1.5),
      ),
    );
  }
}
