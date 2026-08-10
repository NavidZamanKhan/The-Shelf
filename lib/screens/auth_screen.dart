import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:the_shelf/blocs/auth/auth_bloc.dart';
import 'package:the_shelf/blocs/auth/auth_event.dart';
import 'package:the_shelf/blocs/auth/auth_state.dart';
import 'package:the_shelf/blocs/theme/theme_cubit.dart';
import 'package:the_shelf/theme/app_color_palette.dart';
import 'package:the_shelf/theme/app_theme.dart';

/// Screen/modal presenting sign-in options: Google Sign-In & Email Magic Link placeholder.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AuthScreen(),
    );
  }

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showStage3Toast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Email Magic Link sign-in will be available in Stage 3!',
          style: TextStyle(
            fontFamily: AppTheme.serifFontFamily,
            fontSize: 14,
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePalette = context.watch<ThemeCubit>().state;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          Navigator.of(context).pop();
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: Container(
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
              const SizedBox(height: 24),

              // --- Book Header Icon Badge ---
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: activePalette.subtleBadgeBackground,
                  borderRadius: AppTheme.asymmetricBadgeRadius,
                  border: Border.all(color: activePalette.cardBorder, width: 1.2),
                ),
                child: Icon(
                  PhosphorIcons.books,
                  size: 36,
                  color: activePalette.primaryAccent,
                ),
              ),
              const SizedBox(height: 16),

              // Headline & Subtitle
              Text(
                'Welcome to The Shelf',
                style: TextStyle(
                  fontFamily: AppTheme.serifFontFamily,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: activePalette.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Sign in to sync your library across devices',
                style: TextStyle(
                  fontSize: 14,
                  color: activePalette.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // --- Custom Google Sign-In Button ---
              _buildGoogleSignInButton(context, activePalette),
              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: activePalette.cardBorder)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR EMAIL MAGIC LINK',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: activePalette.desaturatedEmptyText,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: activePalette.cardBorder)),
                ],
              ),
              const SizedBox(height: 20),

              // --- Stage 3 Email Input Shell ---
              _buildEmailSection(activePalette),
              const SizedBox(height: 20),

              // Skip / Guest Mode CTA
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Continue as Guest',
                  style: TextStyle(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: 14,
                    color: activePalette.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleSignInButton(
    BuildContext context,
    AppColorPalette activePalette,
  ) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return GestureDetector(
          onTap: isLoading
              ? null
              : () {
                  context.read<AuthBloc>().add(const SignInWithGoogleRequested());
                },
          child: AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: activePalette.cardBackground,
                borderRadius: AppTheme.asymmetricCardRadius,
                border: Border.all(
                  color: activePalette.cardBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: activePalette.primaryText.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isLoading
                  ? SizedBox(
                      height: 20,
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: activePalette.primaryAccent,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          PhosphorIcons.googleLogo,
                          size: 20,
                          color: activePalette.primaryAccent,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontFamily: AppTheme.serifFontFamily,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: activePalette.primaryText,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmailSection(AppColorPalette activePalette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                PhosphorIcons.envelopeSimple,
                size: 18,
                color: activePalette.secondaryText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    fontSize: 14,
                    color: activePalette.primaryText,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your email',
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
        const SizedBox(height: 10),

        // Send Link Button (Stage 3 Toast)
        GestureDetector(
          onTap: _showStage3Toast,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: activePalette.subtleBadgeBackground,
              borderRadius: AppTheme.asymmetricCardRadius,
              border: Border.all(
                color: activePalette.cardBorder,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Send Magic Link',
                  style: TextStyle(
                    fontFamily: AppTheme.serifFontFamily,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: activePalette.secondaryText,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: activePalette.primaryAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Stage 3',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: activePalette.primaryAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
